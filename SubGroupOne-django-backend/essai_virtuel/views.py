from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from .face_detection import essayer_monture

class EssayerMontureView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        image_base64 = request.data.get('image')
        couleur = request.data.get('couleur', 'noir')

        if not image_base64:
            return Response(
                {'erreur': 'Aucune image fournie'},
                status=status.HTTP_400_BAD_REQUEST
            )

        resultat = essayer_monture(image_base64, couleur)

        if not resultat['succes']:
            return Response(
                {'erreur': resultat['erreur']},
                status=status.HTTP_400_BAD_REQUEST
            )

        return Response({
            'message': 'Monture essayée avec succès',
            'image_avec_monture': resultat['image'],
            'position': resultat['position_monture'],
            'points_visage_detectes': resultat['nombre_points_visage']
        })