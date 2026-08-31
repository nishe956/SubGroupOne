"""Validateurs de fichiers réutilisables."""
import io
import os
import uuid

from django.conf import settings
from rest_framework.exceptions import ValidationError

# Signatures magiques des formats autorisés
_SIGNATURES = {
    b'\xff\xd8\xff': 'image/jpeg',
    b'\x89PNG\r\n\x1a\n': 'image/png',
    b'GIF87a': 'image/gif',
    b'GIF89a': 'image/gif',
    b'RIFF': 'image/webp',   # vérification partielle, complétée ci-dessous
    b'%PDF': 'application/pdf',
}

_EXTENSIONS = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'application/pdf': '.pdf',
}

# Une ordonnance photographiée au téléphone pèse couramment 4 à 8 Mo : une
# limite trop basse rejette des fichiers parfaitement légitimes. La protection
# contre les images piégées repose sur `_verifier_dimensions`, pas sur le poids.
_TAILLE_MAX_IMAGE = 12 * 1024 * 1024   # 12 Mo
_TAILLE_MAX_PDF   = 20 * 1024 * 1024   # 20 Mo


def _verifier_dimensions(fichier):
    """Refuse les images dont le nombre de pixels décodés est déraisonnable.

    Une image très compressée de très grandes dimensions (« decompression bomb »)
    tient dans quelques kilo-octets mais alloue plusieurs gigaoctets une fois
    décodée : la seule limite de taille du fichier ne protège pas.
    """
    from PIL import Image

    position = fichier.tell()
    try:
        fichier.seek(0)
        with Image.open(io.BytesIO(fichier.read())) as image:
            largeur, hauteur = image.size
    except Exception:
        raise ValidationError("Image illisible ou corrompue.")
    finally:
        fichier.seek(position)

    maximum = getattr(settings, 'IMAGE_MAX_PIXELS', 50_000_000)
    if largeur * hauteur > maximum:
        raise ValidationError(
            f"Image trop grande ({largeur}×{hauteur} px). "
            f"Maximum autorisé : {maximum} pixels."
        )


def valider_fichier_image_ou_pdf(fichier):
    """Accepte uniquement JPEG, PNG, GIF, WebP ou PDF. Vérifie le contenu réel."""
    if fichier.size > _TAILLE_MAX_PDF:
        raise ValidationError("Le fichier dépasse la taille maximale autorisée (20 Mo).")

    entete = fichier.read(12)
    fichier.seek(0)

    mime = None
    for sig, m in _SIGNATURES.items():
        if entete.startswith(sig):
            mime = m
            break
    # WebP : RIFF....WEBP
    if entete[:4] == b'RIFF' and entete[8:12] == b'WEBP':
        mime = 'image/webp'
    elif entete[:4] == b'RIFF':
        # RIFF sans marqueur WEBP : conteneur audio/vidéo, pas une image.
        mime = None

    if mime is None:
        raise ValidationError(
            "Type de fichier non autorisé. Formats acceptés : JPEG, PNG, GIF, WebP, PDF."
        )

    if mime == 'application/pdf':
        if fichier.size > _TAILLE_MAX_PDF:
            raise ValidationError("Le PDF dépasse la taille maximale (20 Mo).")
    else:
        if fichier.size > _TAILLE_MAX_IMAGE:
            raise ValidationError("L'image dépasse la taille maximale (12 Mo).")
        _verifier_dimensions(fichier)

    return mime


def valider_image_seulement(fichier):
    """Accepte uniquement les images (pas de PDF)."""
    mime = valider_fichier_image_ou_pdf(fichier)
    if mime == 'application/pdf':
        raise ValidationError("Seules les images sont acceptées ici (JPEG, PNG, GIF, WebP).")
    return mime


def nom_fichier_sur(mime, prefixe=''):
    """Construit un nom de fichier aléatoire à partir du type réel du contenu.

    Le nom fourni par le client n'est jamais réutilisé : il sert d'oracle
    (les documents deviennent devinables) et peut contenir des séquences de
    traversée de répertoire.
    """
    extension = _EXTENSIONS.get(mime, '.bin')
    return f"{prefixe}{uuid.uuid4().hex}{extension}"


def extension_sure(nom, autorisees):
    """Retourne l'extension en minuscules si elle fait partie des extensions
    autorisées, sinon None. Ne conserve jamais le reste du nom d'origine."""
    extension = os.path.splitext(nom or '')[1].lower()
    return extension if extension in autorisees else None
