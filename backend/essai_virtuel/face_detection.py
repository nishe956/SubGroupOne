import cv2
import numpy as np
import base64
import binascii
import os
import mediapipe as mp

from .couleurs import COULEURS


LARGEUR_MAX = 4000
HAUTEUR_MAX = 4000
PIXELS_MAX = 12_000_000

CHEMIN_MODELE = os.path.join(os.path.dirname(__file__), 'face_landmarker.task')


class ImageInvalide(Exception):
    """Erreur imputable à l'image fournie — message affichable à l'utilisateur."""


def decoder_image(image_base64):
    if ',' in image_base64:
        image_base64 = image_base64.split(',', 1)[1]

    try:
        image_bytes = base64.b64decode(image_base64, validate=True)
    except (binascii.Error, ValueError):
        raise ImageInvalide("Image illisible.")

    image_array = np.frombuffer(image_bytes, dtype=np.uint8)
    if image_array.size == 0:
        raise ImageInvalide("Image vide.")

    # `IMREAD_REDUCED_COLOR_2` n'est pas utilisé : on veut connaître les
    # dimensions réelles avant d'accepter le décodage complet.
    image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)
    if image is None:
        raise ImageInvalide("Format d'image non reconnu.")

    hauteur, largeur = image.shape[:2]
    if largeur > LARGEUR_MAX or hauteur > HAUTEUR_MAX or largeur * hauteur > PIXELS_MAX:
        raise ImageInvalide(
            f"Image trop grande ({largeur}×{hauteur}). "
            f"Maximum : {LARGEUR_MAX}×{HAUTEUR_MAX} pixels."
        )

    return image

def encoder_image(image):
    _, buffer = cv2.imencode('.jpg', image)
    image_base64 = base64.b64encode(buffer).decode('utf-8')
    return f"data:image/jpeg;base64,{image_base64}"

def detecter_visage(image):
    # Nouvelle API MediaPipe 0.10+
    BaseOptions = mp.tasks.BaseOptions
    FaceLandmarker = mp.tasks.vision.FaceLandmarker
    FaceLandmarkerOptions = mp.tasks.vision.FaceLandmarkerOptions
    VisionRunningMode = mp.tasks.vision.RunningMode

    options = FaceLandmarkerOptions(
        # Chemin absolu : un chemin relatif dépend du répertoire de travail du
        # process, qui n'est pas garanti sous gunicorn.
        base_options=BaseOptions(model_asset_path=CHEMIN_MODELE),
        running_mode=VisionRunningMode.IMAGE,
        num_faces=1,
    )

    hauteur, largeur = image.shape[:2]
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(
        image_format=mp.ImageFormat.SRGB,
        data=image_rgb
    )

    with FaceLandmarker.create_from_options(options) as landmarker:
        result = landmarker.detect(mp_image)

    if not result.face_landmarks:
        return None

    points = []
    for landmark in result.face_landmarks[0]:
        x = int(landmark.x * largeur)
        y = int(landmark.y * hauteur)
        points.append({'x': x, 'y': y})

    return points

def calculer_position_monture(points):
    if not points or len(points) < 468:
        return None
    oeil_gauche = points[33]
    oeil_droit = points[263]
    sourcil_gauche = points[70]
    largeur_monture = abs(oeil_droit['x'] - oeil_gauche['x']) + 60
    hauteur_monture = int(largeur_monture * 0.4)
    x = oeil_gauche['x'] - 30
    y = sourcil_gauche['y'] - 10
    return {
        'x': x,
        'y': y,
        'largeur': largeur_monture,
        'hauteur': hauteur_monture,
        'centre_x': (oeil_gauche['x'] + oeil_droit['x']) // 2,
        'centre_y': (oeil_gauche['y'] + oeil_droit['y']) // 2,
    }

def superposer_monture(image, position, couleur_monture=(0, 0, 0)):
    if not position:
        return image
    image_result = image.copy()
    x = position['x']
    y = position['y']
    largeur = position['largeur']
    hauteur = position['hauteur']
    quart_largeur = largeur // 4
    demi_largeur = largeur // 2

    cv2.ellipse(image_result,
        (x + quart_largeur, y + hauteur // 2),
        (quart_largeur - 5, hauteur // 2 - 5),
        0, 0, 360, couleur_monture, 3)

    cv2.ellipse(image_result,
        (x + demi_largeur + quart_largeur, y + hauteur // 2),
        (quart_largeur - 5, hauteur // 2 - 5),
        0, 0, 360, couleur_monture, 3)

    cv2.line(image_result,
        (x + demi_largeur - quart_largeur + 5, y + hauteur // 2),
        (x + demi_largeur + quart_largeur - 5, y + hauteur // 2),
        couleur_monture, 3)

    cv2.line(image_result,
        (x, y + hauteur // 2),
        (x - 30, y + hauteur // 2),
        couleur_monture, 3)

    cv2.line(image_result,
        (x + largeur, y + hauteur // 2),
        (x + largeur + 30, y + hauteur // 2),
        couleur_monture, 3)

    return image_result

def essayer_monture(image_base64, couleur='noir'):
    
    couleur_rgb = COULEURS.get(couleur, COULEURS['noir'])
    try:
        image = decoder_image(image_base64)
        points = detecter_visage(image)
        if not points:
            return {
                'succes': False,
                'erreur': 'Aucun visage détecté sur la photo.',
                'public': True,
                'image': None,
            }
        position = calculer_position_monture(points)
        if not position:
            return {
                'succes': False,
                'erreur': "Le visage n'est pas assez net pour positionner la monture.",
                'public': True,
                'image': None,
            }
        image_result = superposer_monture(image, position, couleur_rgb)
        return {
            'succes': True,
            'image': encoder_image(image_result),
            'position_monture': position,
            'nombre_points_visage': len(points),
        }
    except ImageInvalide as exc:
        return {'succes': False, 'erreur': str(exc), 'public': True, 'image': None}
    except Exception as exc:
        return {'succes': False, 'erreur': repr(exc), 'public': False, 'image': None}