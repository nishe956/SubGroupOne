from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from .models import GroupeFamille
from .serializers import GroupeFamilleSerializer
from django.core.mail import send_mail
from django.conf import settings


class MonGroupe(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        groupe = GroupeFamille.objects.filter(membres=request.user, actif=True).first()
        if not groupe:
            groupe = GroupeFamille.objects.filter(chef=request.user, actif=True).first()
        if not groupe:
            return Response(None)
        return Response(GroupeFamilleSerializer(groupe, context={'request': request}).data)


class CreerGroupe(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Check user doesn't already have a group
        if GroupeFamille.objects.filter(chef=request.user, actif=True).exists():
            return Response({'detail': 'Vous avez déjà un groupe famille.'}, status=status.HTTP_400_BAD_REQUEST)
        groupe = GroupeFamille.objects.create(
            nom=request.data.get('nom', f"Famille {request.user.last_name}"),
            chef=request.user,
        )
        groupe.membres.add(request.user)
        return Response(GroupeFamilleSerializer(groupe).data, status=status.HTTP_201_CREATED)


class InviterMembre(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        groupe = GroupeFamille.objects.filter(chef=request.user, actif=True).first()
        if not groupe:
            return Response({'detail': 'Vous n\'êtes pas chef d\'un groupe.'}, status=status.HTTP_400_BAD_REQUEST)
        email = request.data.get('email')
        if email:
            # Send invitation email
            try:
                send_mail(
                    subject='Invitation groupe famille — OptiLunette',
                    message=f"Vous êtes invité(e) à rejoindre le groupe famille '{groupe.nom}' sur OptiLunette.\n\nCode d'invitation : {groupe.code_invitation}\n\nConnectez-vous et utilisez ce code dans votre espace 'Compte Famille'.",
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[email],
                    fail_silently=True,
                )
            except Exception:
                pass
        return Response({'detail': 'Invitation envoyée.', 'code': groupe.code_invitation})


class RejoindreGroupe(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        code = request.data.get('code', '').upper()
        try:
            groupe = GroupeFamille.objects.get(code_invitation=code, actif=True)
        except GroupeFamille.DoesNotExist:
            return Response({'detail': 'Code invalide.'}, status=status.HTTP_404_NOT_FOUND)
        groupe.membres.add(request.user)
        return Response(GroupeFamilleSerializer(groupe).data)


class QuitterGroupe(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        groupe = GroupeFamille.objects.filter(membres=request.user, actif=True).exclude(chef=request.user).first()
        if groupe:
            groupe.membres.remove(request.user)
            return Response({'detail': 'Vous avez quitté le groupe.'})
        return Response({'detail': 'Vous n\'êtes pas dans un groupe.'}, status=status.HTTP_400_BAD_REQUEST)


class MembresFamille(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        groupe = GroupeFamille.objects.filter(membres=request.user, actif=True).first()
        if not groupe:
            groupe = GroupeFamille.objects.filter(chef=request.user, actif=True).first()
        if not groupe:
            return Response([])
        from users.serializers import UserSerializer
        return Response(UserSerializer(groupe.membres.all(), many=True).data)


class RabaisFamille(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        groupe = GroupeFamille.objects.filter(membres=request.user, actif=True).first()
        if not groupe:
            return Response({'taux': 0, 'nb_membres': 1})
        return Response({
            'taux': groupe.taux_rabais(),
            'nb_membres': groupe.nb_membres(),
            'groupe': groupe.nom,
        })
