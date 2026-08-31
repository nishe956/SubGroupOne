import logging

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from users.permissions import CompteUtilisable
from utils.throttles import ThrottleEssai

from .couleurs import COULEURS

logger = logging.getLogger(__name__)

# Taille maximale de la chaîne base64 acceptée (~3 Mo une fois décodée).
TAILLE_MAX_BASE64 = 4 * 1024 * 1024


class EssayerMontureView(APIView):
    permission_classes = [CompteUtilisable]
    # Décodage d'image + inférence MediaPipe : coûteux en CPU et en mémoire.
    throttle_classes = [ThrottleEssai]

    def post(self, request):
        image_base64 = request.data.get('image')
        couleur = request.data.get('couleur', 'noir')

        if not image_base64 or not isinstance(image_base64, str):
            return Response({'erreur': 'Aucune image fournie'}, status=status.HTTP_400_BAD_REQUEST)

        if len(image_base64) > TAILLE_MAX_BASE64:
            return Response(
                {'erreur': 'Image trop volumineuse.'},
                status=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            )

        if couleur not in COULEURS:
            couleur = 'noir'

        # Import différé : `face_detection` charge OpenCV et MediaPipe, soit une
        # centaine de mégaoctets résidents. Importé au niveau du module, ce coût
        # était payé au démarrage par CHAQUE worker, y compris ceux qui ne
        # servent jamais d'essai virtuel — de quoi dépasser les 512 Mo d'un
        # hébergement gratuit et allonger d'autant les démarrages à froid.
        from .face_detection import essayer_monture

        resultat = essayer_monture(image_base64, couleur)

        if not resultat['succes']:
            # `resultat['erreur']` peut contenir un message d'OpenCV ou de
            # MediaPipe (chemins internes, versions) : on ne renvoie que les
            # messages explicitement destinés à l'utilisateur.
            message = resultat['erreur'] if resultat.get('public') else \
                "L'essai virtuel a échoué. Réessayez avec une autre photo."
            if not resultat.get('public'):
                logger.warning("Échec essai virtuel : %s", resultat['erreur'])
            return Response({'erreur': message}, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            'message': 'Monture essayée avec succès',
            'image_avec_monture': resultat['image'],
            'position': resultat['position_monture'],
            'points_visage_detectes': resultat['nombre_points_visage'],
        })
