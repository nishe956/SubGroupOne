from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import BoutiqueOpticien
from .serializers import BoutiqueSerializer


class MaBoutique(APIView):
    """Opticien GET/PUT sa propre boutique."""
    permission_classes = [permissions.IsAuthenticated]

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
        serializer = BoutiqueSerializer(boutique, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DetailBoutique(generics.RetrieveAPIView):
    """Accès public au détail d'une boutique."""
    queryset = BoutiqueOpticien.objects.filter(actif=True)
    serializer_class = BoutiqueSerializer
    permission_classes = [permissions.AllowAny]


class ListeBoutiques(generics.ListAPIView):
    """Liste publique de toutes les boutiques actives.
    Supporte ?opticien=<user_id> pour filtrer par opticien."""
    serializer_class = BoutiqueSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = BoutiqueOpticien.objects.filter(actif=True).order_by('nom')
        opticien_id = self.request.query_params.get('opticien')
        if opticien_id:
            qs = qs.filter(opticien_id=opticien_id)
        return qs
