from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from users.permissions import CompteUtilisable
from utils.validators import valider_image_seulement

from .models import BoutiqueOpticien
from .serializers import BoutiqueSerializer


class MaBoutique(APIView):
    """Opticien GET/PUT sa propre boutique."""
    # CompteUtilisable plutôt que IsAuthenticated : un opticien rejeté ne doit
    # plus pouvoir modifier la vitrine qui porte son nom.
    permission_classes = [CompteUtilisable]

    def get(self, request):
        try:
            boutique = BoutiqueOpticien.objects.get(opticien=request.user)
        except BoutiqueOpticien.DoesNotExist:
            return Response({'detail': 'Aucune boutique trouvée.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(BoutiqueSerializer(boutique).data)

    def put(self, request):
        try:
            boutique = BoutiqueOpticien.objects.get(opticien=request.user)
        except BoutiqueOpticien.DoesNotExist:
            return Response({'detail': 'Aucune boutique trouvée.'}, status=status.HTTP_404_NOT_FOUND)
        logo = request.FILES.get('logo')
        if logo:
            valider_image_seulement(logo)
        serializer = BoutiqueSerializer(boutique, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DetailBoutique(generics.RetrieveAPIView):
    """Accès public au détail d'une boutique (opticien approuvé uniquement)."""
    queryset = BoutiqueOpticien.objects.filter(
        actif=True, opticien__statut_validation='approuve'
    )
    serializer_class = BoutiqueSerializer
    permission_classes = [permissions.AllowAny]


class ListeBoutiques(generics.ListAPIView):
    """Liste publique des boutiques actives d'opticiens approuvés.
    Supporte ?opticien=<user_id> pour filtrer par opticien."""
    serializer_class = BoutiqueSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = BoutiqueOpticien.objects.filter(
            actif=True, opticien__statut_validation='approuve'
        ).order_by('nom')
        opticien_id = self.request.query_params.get('opticien')
        if opticien_id:
            qs = qs.filter(opticien_id=opticien_id)
        return qs
