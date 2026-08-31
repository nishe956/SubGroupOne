import logging
import os
import re

from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from utils.audit import journaliser
from utils.throttles import ThrottleOTP

from .models import DUREE_VALIDITE, TENTATIVES_MAX, OTPCode, generer_code, hacher_code
from .sms_service import envoyer_sms

logger = logging.getLogger(__name__)

# Numéro au format international. Le numéro n'était pas validé du tout :
# l'endpoint étant public, il permettait de faire envoyer des SMS facturés vers
# n'importe quel numéro dans le monde, y compris des préfixes surtaxés.
MOTIF_TELEPHONE = re.compile(r'^\+[1-9]\d{7,14}$')

# Préfixes desservis. À élargir au fur et à mesure des marchés couverts.
PREFIXES_AUTORISES = tuple(
    p.strip() for p in os.environ.get('SMS_PREFIXES_AUTORISES', '+226,+225,+223,+227,+228,+229').split(',')
    if p.strip()
)


def _normaliser(telephone):
    """Retourne le numéro au format E.164, ou None s'il est inexploitable."""
    numero = re.sub(r'[\s.\-()]', '', telephone or '')
    if numero.startswith('00'):
        numero = '+' + numero[2:]
    if not MOTIF_TELEPHONE.match(numero):
        return None
    if PREFIXES_AUTORISES and not numero.startswith(PREFIXES_AUTORISES):
        return None
    return numero


class EnvoyerOTP(APIView):
    permission_classes = [permissions.AllowAny]
    # Quota par IP, en plus du quota par numéro : sans lui, il suffisait de faire
    # tourner les numéros pour envoyer un volume illimité de SMS facturés.
    throttle_classes = [ThrottleOTP]

    MAX_PAR_NUMERO = 3

    def post(self, request):
        telephone = _normaliser(request.data.get('telephone', ''))
        if telephone is None:
            return Response(
                {'detail': "Numéro invalide. Format attendu : +226XXXXXXXX."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        type_otp = request.data.get('type', 'login')
        if type_otp not in dict(OTPCode.TYPES):
            type_otp = 'login'

        recents = OTPCode.objects.filter(
            telephone=telephone,
            created_at__gte=timezone.now() - DUREE_VALIDITE,
        ).count()
        if recents >= self.MAX_PAR_NUMERO:
            return Response(
                {'detail': 'Trop de demandes. Réessayez dans 10 minutes.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        # Invalide les codes précédents encore actifs.
        OTPCode.objects.filter(telephone=telephone, used=False).update(used=True)

        code = generer_code()
        OTPCode.objects.create(
            telephone=telephone, code_hash=hacher_code(code), type=type_otp,
        )

        message = (
            f"OptiLunette — Votre code de vérification : {code}. "
            f"Valide 10 minutes. Ne partagez jamais ce code."
        )
        if not envoyer_sms(telephone, message):
            logger.warning("SMS non envoyé pour %s", telephone)

        journaliser('otp_envoye', None, telephone=telephone, type=type_otp)

        # Le code n'est renvoyé dans la réponse HTTP en AUCUN cas : il doit
        # transiter uniquement par le canal SMS. En développement, il est
        # consultable dans les logs du fournisseur « mock ».
        return Response({'detail': 'Code OTP envoyé par SMS.', 'expires_in': 600})


class VerifierOTP(APIView):
    """Vérifie un code reçu par SMS.

    ⚠️ Cet endpoint ne délivre AUCUN jeton d'authentification et ne connecte
    personne : il atteste seulement qu'un code valide a été présenté pour un
    numéro donné. Ne jamais l'utiliser côté frontend pour ouvrir une session —
    l'émission des jetons doit rester du ressort du backend, après vérification
    d'un mot de passe ou d'un fournisseur d'identité.
    """
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ThrottleOTP]

    def post(self, request):
        telephone = _normaliser(request.data.get('telephone', ''))
        code = str(request.data.get('code', '')).strip()

        if telephone is None or not code:
            return Response(
                {'detail': 'Téléphone et code requis.'}, status=status.HTTP_400_BAD_REQUEST
            )

        otp = (
            OTPCode.objects
            .filter(telephone=telephone, used=False)
            .order_by('-created_at')
            .first()
        )
        if otp is None:
            return Response(
                {'detail': 'Aucun code actif pour ce numéro.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp.attempts += 1
        otp.save(update_fields=['attempts'])

        if not otp.is_valid():
            return Response(
                {'detail': 'Code expiré ou trop de tentatives. Demandez un nouveau code.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not otp.verifier(code):
            restantes = max(0, TENTATIVES_MAX - otp.attempts)
            return Response(
                {'detail': f'Code incorrect. {restantes} tentative(s) restante(s).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp.used = True
        otp.save(update_fields=['used'])
        journaliser('otp_verifie', None, telephone=telephone)

        return Response({'detail': 'Code vérifié avec succès.', 'verified': True})
