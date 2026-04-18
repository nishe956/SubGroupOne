import pytesseract
from PIL import Image
from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from .models import Ordonnance
from .serializers import OrdonnanceSerializer
from users.permissions import IsAdminOrOpticianRole
from rest_framework import filters
from django.conf import settings
import os

class OrdonnanceListView(generics.ListAPIView):
    serializer_class = OrdonnanceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Ordonnance.objects.filter(user=self.request.user).order_by('-date_scan')

class ScannerOrdonnanceView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        image_file = request.FILES.get('image')
        if not image_file:
            return Response({'error': 'Aucune image fournie.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            # Configurer le chemin de Tesseract s'il est dfini dans l'env
            tess_path = os.getenv('TESSERACT_PATH')
            if tess_path and os.path.exists(tess_path):
                pytesseract.pytesseract.tesseract_cmd = tess_path
            
            img = Image.open(image_file)
            texte = pytesseract.image_to_string(img, lang='fra+eng')
            
            if not texte.strip():
                texte = "Aucun texte extrait (image vide ou illisible)."
        except Exception as e:
            texte = f"Erreur de scan : Assurez-vous que Tesseract est install et configur. ({str(e)})"

        ordonnance = Ordonnance.objects.create(
            user=request.user,
            image=image_file,
            texte_extrait=texte,
        )
        return Response({
            'id': ordonnance.id,
            'texte_extrait': texte,
            'date_scan': ordonnance.date_scan,
        }, status=status.HTTP_201_CREATED)

class AdminOrdonnanceListView(generics.ListAPIView):
    """
    Vue pour permettre aux admins et opticiens de voir toutes les ordonnances.
    Supporte la recherche par texte extrait ou email utilisateur.
    """
    queryset = Ordonnance.objects.all().order_by('-date_scan')
    serializer_class = OrdonnanceSerializer
    permission_classes = [IsAdminOrOpticianRole]
    filter_backends = [filters.SearchFilter]
    search_fields = ['texte_extrait', 'user__email', 'user__first_name', 'user__last_name']
