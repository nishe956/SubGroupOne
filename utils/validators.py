"""Validateurs de fichiers réutilisables."""
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

_TAILLE_MAX_IMAGE = 10 * 1024 * 1024   # 10 Mo
_TAILLE_MAX_PDF   = 20 * 1024 * 1024   # 20 Mo


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

    if mime is None:
        raise ValidationError(
            "Type de fichier non autorisé. Formats acceptés : JPEG, PNG, GIF, WebP, PDF."
        )

    if mime == 'application/pdf' and fichier.size > _TAILLE_MAX_PDF:
        raise ValidationError("Le PDF dépasse la taille maximale (20 Mo).")

    if mime != 'application/pdf' and fichier.size > _TAILLE_MAX_IMAGE:
        raise ValidationError("L'image dépasse la taille maximale (10 Mo).")

    return mime


def valider_image_seulement(fichier):
    """Accepte uniquement les images (pas de PDF)."""
    mime = valider_fichier_image_ou_pdf(fichier)
    if mime == 'application/pdf':
        raise ValidationError("Seules les images sont acceptées ici (JPEG, PNG, GIF, WebP).")
    return mime
