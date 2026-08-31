"""Palette des montures de l'essai virtuel.

Ce module est volontairement séparé de ``face_detection`` : il permet aux vues
de valider la couleur demandée sans importer OpenCV ni MediaPipe, qui coûtent à
eux deux une centaine de mégaoctets de mémoire résidente.
"""

# Valeurs en BGR : c'est l'ordre de canaux attendu par OpenCV.
COULEURS = {
    'noir': (0, 0, 0),
    'marron': (42, 82, 139),
    'or': (0, 215, 255),
    'argent': (192, 192, 192),
    'rouge': (0, 0, 255),
    'bleu': (255, 0, 0),
}
