from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from .models import EssaiVirtuel
from .serializers import EssaiVirtuelSerializer

class EssaiVirtuelListView(generics.ListAPIView):
    serializer_class = EssaiVirtuelSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return EssaiVirtuel.objects.filter(user=self.request.user).order_by('-date_essai')

class CreerEssaiView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        monture_id = request.data.get('monture_id')
        image_file = request.FILES.get('image')
        if not monture_id or not image_file:
            return Response({'error': 'monture_id et image sont requis.'}, status=status.HTTP_400_BAD_REQUEST)
        from montures.models import Monture
        try:
            monture = Monture.objects.get(id=monture_id)
        except Monture.DoesNotExist:
            return Response({'error': 'Monture introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        essai = EssaiVirtuel.objects.create(
            user=request.user,
            monture=monture,
            image_utilisateur=image_file,
        )

        # Vérification de l'image de la monture
        if not monture.image:
            return Response({'error': 'Cette monture n\'a pas d\'image associée.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            from .ai_logic import VirtualTryOnEngine
            import os
            from django.conf import settings
            
            engine = VirtualTryOnEngine()
            
            # Chemins absolus
            user_img_path = essai.image_utilisateur.path
            glasses_img_path = monture.image.path
            
            # Chemin de sortie
            result_dir = os.path.join(settings.MEDIA_ROOT, 'essais', 'resultats')
            os.makedirs(result_dir, exist_ok=True)
            result_filename = f"result_{essai.id}.jpg"
            result_path = os.path.join(result_dir, result_filename)
            
            # Traitement
            success = engine.process_try_on(user_img_path, glasses_img_path, result_path)
            
            if success:
                essai.image_resultat = f"essais/resultats/{result_filename}"
                essai.save()
            else:
                print("L'IA n'a pas pu traiter l'image (visage non détecté ou hors limites).")
        except Exception as e:
            import traceback
            print("--- ERREUR CRITIQUE IA ---")
            print(f"Exception : {str(e)}")
            traceback.print_exc()
            print("--------------------------")

        return Response(EssaiVirtuelSerializer(essai).data, status=status.HTTP_201_CREATED)
