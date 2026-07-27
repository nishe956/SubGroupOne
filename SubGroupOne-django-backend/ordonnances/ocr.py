import pytesseract
import cv2
import numpy as np
import re
import os
from PIL import Image
from dotenv import load_dotenv

load_dotenv()

# Indique à pytesseract où trouver Tesseract
pytesseract.pytesseract.tesseract_cmd = os.getenv('TESSERACT_PATH')

def ameliorer_image(image_path):
    """
    Améliore la qualité de l'image avant de la lire
    Plus l'image est claire, meilleure est la lecture OCR
    """
    # Charge l'image avec OpenCV
    image = cv2.imread(image_path)
    
    # Convertit en niveaux de gris
    gris = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Augmente le contraste
    gris = cv2.equalizeHist(gris)
    
    # Réduit le bruit
    gris = cv2.GaussianBlur(gris, (3, 3), 0)
    
    # Binarisation (noir et blanc pur)
    _, binaire = cv2.threshold(
        gris, 0, 255, 
        cv2.THRESH_BINARY + cv2.THRESH_OTSU
    )
    
    return binaire

def extraire_texte(image_path):
    """
    Extrait tout le texte d'une image d'ordonnance
    """
    # Améliore l'image d'abord
    image_amelioree = ameliorer_image(image_path)
    
    # Convertit pour pytesseract
    image_pil = Image.fromarray(image_amelioree)
    
    # Extrait le texte en français et anglais
    texte = pytesseract.image_to_string(
        image_pil, 
        lang='fra+eng',
        config='--psm 6'
    )
    
    return texte

def extraire_valeurs_optiques(texte):
    """
    Analyse le texte extrait et trouve les valeurs optiques
    Les ordonnances contiennent : sphère, cylindre, axe
    Exemple dans une ordonnance: OD: +1.50 -0.75 180
    """
    resultats = {
        'oeil_droit_sphere': None,
        'oeil_droit_cylindre': None,
        'oeil_droit_axe': None,
        'oeil_gauche_sphere': None,
        'oeil_gauche_cylindre': None,
        'oeil_gauche_axe': None,
    }
    
    # Patterns pour trouver les valeurs
    # Une valeur optique ressemble à : +1.50 ou -0.75 ou 1.25
    pattern_valeur = r'[+-]?\d+[.,]\d+'
    pattern_axe = r'\d{1,3}'
    
    lignes = texte.lower().split('\n')
    
    for ligne in lignes:
        valeurs = re.findall(pattern_valeur, ligne)
        valeurs = [float(v.replace(',', '.')) for v in valeurs]
        
        # Cherche oeil droit (OD, od, droit, right, RE)
        if any(mot in ligne for mot in ['od', 'oeil droit', 'droit', 'right', 're', 'o.d']):
            if len(valeurs) >= 1:
                resultats['oeil_droit_sphere'] = valeurs[0]
            if len(valeurs) >= 2:
                resultats['oeil_droit_cylindre'] = valeurs[1]
            # Cherche l'axe (nombre entre 0 et 180)
            axes = re.findall(r'\b([0-9]|[1-9][0-9]|1[0-7][0-9]|180)\b', ligne)
            if axes:
                resultats['oeil_droit_axe'] = float(axes[-1])
        
        # Cherche oeil gauche (OG, og, gauche, left, LE)
        if any(mot in ligne for mot in ['og', 'oeil gauche', 'gauche', 'left', 'le', 'o.g']):
            if len(valeurs) >= 1:
                resultats['oeil_gauche_sphere'] = valeurs[0]
            if len(valeurs) >= 2:
                resultats['oeil_gauche_cylindre'] = valeurs[1]
            axes = re.findall(r'\b([0-9]|[1-9][0-9]|1[0-7][0-9]|180)\b', ligne)
            if axes:
                resultats['oeil_gauche_axe'] = float(axes[-1])
    
    return resultats

def analyser_ordonnance(image_path):
    """
    Fonction principale qui combine tout :
    1. Extrait le texte de l'image
    2. Analyse le texte pour trouver les valeurs optiques
    3. Retourne un résultat complet
    """
    try:
        texte_brut = extraire_texte(image_path)
        valeurs = extraire_valeurs_optiques(texte_brut)
        
        return {
            'succes': True,
            'texte_brut': texte_brut,
            'valeurs_optiques': valeurs
        }
    except Exception as e:
        return {
            'succes': False,
            'erreur': str(e),
            'valeurs_optiques': None
        }