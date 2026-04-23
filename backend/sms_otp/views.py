from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from django.utils import timezone
from .models import OTPCode
from .sms_service import envoyer_sms
import logging

logger = logging.getLogger(__name__)


class EnvoyerOTP(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        telephone = request.data.get('telephone', '').strip()
        type_otp  = request.data.get('type', 'login')

        if not telephone:
            return Response({'detail': 'Numéro de téléphone requis.'}, status=status.HTTP_400_BAD_REQUEST)

        # Rate limiting: max 3 OTP per 10 minutes
        recent = OTPCode.objects.filter(
            telephone=telephone,
            created_at__gte=timezone.now() - timezone.timedelta(minutes=10),
        ).count()
        if recent >= 3:
            return Response({'detail': 'Trop de tentatives. Réessayez dans 10 minutes.'}, status=status.HTTP_429_TOO_MANY_REQUESTS)

        # Invalidate old codes
        OTPCode.objects.filter(telephone=telephone, used=False).update(used=True)

        # Create new OTP
        otp = OTPCode.objects.create(telephone=telephone, type=type_otp)

        # Send SMS
        message = f"OptiLunette — Votre code de vérification : {otp.code}. Valide 10 minutes. Ne partagez jamais ce code."
        sent = envoyer_sms(telephone, message)

        import os
        is_dev = os.environ.get('DJANGO_ENV') == 'development'
        is_mock = os.environ.get('SMS_PROVIDER', 'mock') == 'mock'

        if not sent:
            logger.warning(f"SMS non envoyé pour {telephone}")

        # Code visible uniquement si développement ET mock simultanément (jamais en prod)
        if is_dev and is_mock:
            return Response({
                'detail': 'Code OTP généré (mode test local).',
                'code_dev': otp.code,
                'expires_in': 600,
            })

        return Response({'detail': 'Code OTP envoyé par SMS.', 'expires_in': 600})


class VerifierOTP(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        telephone = request.data.get('telephone', '').strip()
        code      = request.data.get('code', '').strip()

        if not telephone or not code:
            return Response({'detail': 'Téléphone et code requis.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            otp = OTPCode.objects.filter(
                telephone=telephone,
                used=False,
            ).latest('created_at')
        except OTPCode.DoesNotExist:
            return Response({'detail': 'Aucun code actif pour ce numéro.'}, status=status.HTTP_400_BAD_REQUEST)

        otp.attempts += 1
        otp.save(update_fields=['attempts'])

        if not otp.is_valid():
            return Response({'detail': 'Code expiré ou trop de tentatives. Demandez un nouveau code.'}, status=status.HTTP_400_BAD_REQUEST)

        if otp.code != code:
            remaining = 3 - otp.attempts
            return Response({'detail': f'Code incorrect. {remaining} tentative(s) restante(s).'}, status=status.HTTP_400_BAD_REQUEST)

        otp.used = True
        otp.save(update_fields=['used'])

        return Response({'detail': 'Code vérifié avec succès.', 'verified': True})
