from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from .models import Ordonnance
from .serializers import OrdonnanceSerializer
from .ocr import analyser_ordonnance
import os

class AjouterOrdonnance(generics.CreateAPIView):
    serializer_class = OrdonnanceSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def perform_create(self, serializer):
        serializer.save(client=self.request.user)

class ScannerOrdonnance(APIView):
    """
    Le client envoie une image d'ordonnance
    L'IA extrait automatiquement les valeurs optiques
    """
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        if 'image' not in request.FILES:
            return Response(
                {'erreur': 'Aucune image fournie'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        image = request.FILES['image']
        
        # Sauvegarde temporaire de l'image
        chemin_temp = f'media/temp_{request.user.id}_{image.name}'
        with open(chemin_temp, 'wb+') as f:
            for chunk in image.chunks():
                f.write(chunk)
        
        # Analyse avec l'IA
        resultat = analyser_ordonnance(chemin_temp)
        
        # Supprime le fichier temporaire
        os.remove(chemin_temp)
        
        if not resultat['succes']:
            return Response(
                {'erreur': resultat['erreur']},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        # Sauvegarde l'ordonnance avec les valeurs extraites
        valeurs = resultat['valeurs_optiques']
        ordonnance = Ordonnance.objects.create(
            client=request.user,
            image=image,
            oeil_droit_sphere=valeurs['oeil_droit_sphere'],
            oeil_droit_cylindre=valeurs['oeil_droit_cylindre'],
            oeil_droit_axe=valeurs['oeil_droit_axe'],
            oeil_gauche_sphere=valeurs['oeil_gauche_sphere'],
            oeil_gauche_cylindre=valeurs['oeil_gauche_cylindre'],
            oeil_gauche_axe=valeurs['oeil_gauche_axe'],
        )
        
        return Response({
            'message': 'Ordonnance scannée avec succès',
            'ordonnance_id': ordonnance.id,
            'texte_detecte': resultat['texte_brut'],
            'valeurs_extraites': valeurs
        })

class ListeOrdonnances(generics.ListAPIView):
    serializer_class = OrdonnanceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'client':
            return Ordonnance.objects.filter(client=user)
        return Ordonnance.objects.all()

class DetailOrdonnance(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = OrdonnanceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'client':
            return Ordonnance.objects.filter(client=user)
        return Ordonnance.objects.all()

class ValiderOrdonnance(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        if request.user.role not in ['opticien', 'admin']:
            return Response(
                {'erreur': 'Permission refusée'},
                status=status.HTTP_403_FORBIDDEN
            )
        try:
            ordonnance = Ordonnance.objects.get(pk=pk)
            ordonnance.validee = True
            ordonnance.save()
            return Response({'message': 'Ordonnance validée avec succès'})
        except Ordonnance.DoesNotExist:
            return Response(
                {'erreur': 'Ordonnance introuvable'},
                status=status.HTTP_404_NOT_FOUND
            )