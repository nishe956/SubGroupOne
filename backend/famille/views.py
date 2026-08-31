from django.core.mail import send_mail
from django.conf import settings
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from users.permissions import CompteUtilisable
from utils.audit import journaliser
from utils.throttles import ThrottleInvitation

from .models import GroupeFamille
from .serializers import GroupeFamilleSerializer

MAX_MEMBRES = 8


def _groupe_de(user):
    """Groupe actif de l'utilisateur (comme membre, ou comme chef)."""
    return (
        GroupeFamille.objects.filter(membres=user, actif=True).first()
        or GroupeFamille.objects.filter(chef=user, actif=True).first()
    )


class MonGroupe(APIView):
    permission_classes = [CompteUtilisable]

    def get(self, request):
        groupe = _groupe_de(request.user)
        if not groupe:
            return Response(None)
        return Response(GroupeFamilleSerializer(groupe, context={'request': request}).data)


class CreerGroupe(APIView):
    permission_classes = [CompteUtilisable]

    def post(self, request):
        if GroupeFamille.objects.filter(chef=request.user, actif=True).exists():
            return Response(
                {'detail': 'Vous avez déjà un groupe famille.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        nom = str(request.data.get('nom') or f"Famille {request.user.last_name}").strip()[:100]
        groupe = GroupeFamille.objects.create(nom=nom or 'Ma famille', chef=request.user)
        groupe.membres.add(request.user)
        journaliser('groupe_famille_cree', request.user, groupe_id=groupe.pk)
        return Response(
            GroupeFamilleSerializer(groupe, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )


class InviterMembre(APIView):
    """Envoie le code d'invitation à une adresse email.

    L'endpoint envoyait un email vers une adresse arbitraire, sans limite : il
    constituait un relais de spam et de hameçonnage depuis l'adresse légitime de
    la plateforme. Il est désormais limité par un quota strict, et le nom du
    groupe n'est plus repris dans le corps du message.
    """
    permission_classes = [CompteUtilisable]
    throttle_classes = [ThrottleInvitation]

    def post(self, request):
        groupe = GroupeFamille.objects.filter(chef=request.user, actif=True).first()
        if not groupe:
            return Response(
                {'detail': "Vous n'êtes pas chef d'un groupe."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if groupe.membres.count() >= MAX_MEMBRES:
            return Response(
                {'detail': f'Un groupe famille est limité à {MAX_MEMBRES} membres.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        email = (request.data.get('email') or '').strip()
        if email:
            from django.core.validators import validate_email
            from django.core.exceptions import ValidationError as DjangoValidationError
            try:
                validate_email(email)
            except DjangoValidationError:
                return Response(
                    {'detail': 'Adresse email invalide.'}, status=status.HTTP_400_BAD_REQUEST
                )

            send_mail(
                subject='Invitation groupe famille — OptiLunette',
                message=(
                    "Vous avez été invité(e) à rejoindre un groupe famille sur OptiLunette.\n\n"
                    f"Code d'invitation : {groupe.code_invitation}\n\n"
                    "Connectez-vous et saisissez ce code dans votre espace « Compte Famille ».\n"
                    "Si vous n'attendiez pas cette invitation, ignorez simplement ce message."
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=True,
            )
            journaliser('invitation_famille', request.user, groupe_id=groupe.pk)

        return Response({'detail': 'Invitation envoyée.', 'code': groupe.code_invitation})


class RejoindreGroupe(APIView):
    permission_classes = [CompteUtilisable]
    # Le code d'invitation ne fait que 6 caractères : sans quota, il serait
    # énumérable, et rejoindre un groupe donne accès à la liste de ses membres.
    throttle_classes = [ThrottleInvitation]

    def post(self, request):
        code = str(request.data.get('code', '')).strip().upper()[:6]
        if not code:
            return Response({'detail': 'Code requis.'}, status=status.HTTP_400_BAD_REQUEST)

        groupe = GroupeFamille.objects.filter(code_invitation=code, actif=True).first()
        if groupe is None:
            return Response({'detail': 'Code invalide.'}, status=status.HTTP_404_NOT_FOUND)

        if GroupeFamille.objects.filter(membres=request.user, actif=True).exists():
            return Response(
                {'detail': 'Vous appartenez déjà à un groupe famille.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if groupe.membres.count() >= MAX_MEMBRES:
            return Response(
                {'detail': 'Ce groupe est complet.'}, status=status.HTTP_400_BAD_REQUEST
            )

        groupe.membres.add(request.user)
        journaliser('groupe_famille_rejoint', request.user, groupe_id=groupe.pk)
        return Response(GroupeFamilleSerializer(groupe, context={'request': request}).data)


class QuitterGroupe(APIView):
    permission_classes = [CompteUtilisable]

    def post(self, request):
        groupe = (
            GroupeFamille.objects
            .filter(membres=request.user, actif=True)
            .exclude(chef=request.user)
            .first()
        )
        if groupe:
            groupe.membres.remove(request.user)
            return Response({'detail': 'Vous avez quitté le groupe.'})
        return Response(
            {'detail': "Vous n'êtes pas dans un groupe."},
            status=status.HTTP_400_BAD_REQUEST,
        )


class MembresFamille(APIView):
    permission_classes = [CompteUtilisable]

    def get(self, request):
        groupe = _groupe_de(request.user)
        if not groupe:
            return Response([])

        # Vue restreinte : la version précédente renvoyait le sérialiseur complet,
        # exposant email, téléphone, adresse, date de naissance et numéro de
        # police d'assurance de tous les membres à quiconque rejoint le groupe.
        from users.serializers import UserPublicSerializer
        return Response(UserPublicSerializer(groupe.membres.all(), many=True).data)


class RabaisFamille(APIView):
    permission_classes = [CompteUtilisable]

    def get(self, request):
        groupe = GroupeFamille.objects.filter(membres=request.user, actif=True).first()
        if not groupe:
            return Response({'taux': 0, 'nb_membres': 1})
        # Valeur purement indicative pour l'affichage : le rabais réellement
        # appliqué est recalculé côté serveur au moment de la commande
        # (commandes/tarifs.py).
        return Response({
            'taux': groupe.taux_rabais(),
            'nb_membres': groupe.nb_membres(),
            'groupe': groupe.nom,
        })
