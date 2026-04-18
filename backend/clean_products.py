import os
import django
import cv2
import numpy as np

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from montures.models import Monture
from essai_virtuel.ai_logic import VirtualTryOnEngine

def clean_all_products():
    engine = VirtualTryOnEngine()
    products = Monture.objects.all()
    
    print(f"Dbut du nettoyage de {len(products)} produits...")
    
    for p in products:
        if not p.image:
            print(f"Saut de {p.nom} (pas d'image)")
            continue
            
        img_path = p.image.path
        if not os.path.exists(img_path):
            print(f"Image manquante pour {p.nom}: {img_path}")
            continue
            
        # On ne veut pas traiter les images dj en PNG ou dj dtoures (optionnel)
        # Mais ici on force pour assurer la qualit ultra
        
        print(f"Traitement de {p.nom}...")
        img = cv2.imread(img_path)
        if img is None:
            print(f"Erreur de lecture pour {p.nom}")
            continue
            
        # Utilisation de la nouvelle logique ultra-robuste
        cleaned_img = engine._extract_glasses_ultra(img)
        
        # Sauvegarde en remplaant l'originale ou en PNG
        # Pour le web/flutter, le PNG est prfrable pour la transparence
        base_name = os.path.splitext(img_path)[0]
        new_path = base_name + ".png"
        
        cv2.imwrite(new_path, cleaned_img)
        
        # Mise jour du modle Django pour pointer vers le nouveau fichier PNG
        relative_path = os.path.relpath(new_path, start=os.path.join(os.path.dirname(img_path), '../..'))
        # Django attend un chemin relatif au MEDIA_ROOT
        # Ici on simplifie en rcuprant juste ce qui suit 'media/'
        if 'media' in relative_path:
             relative_path = relative_path.split('media' + os.sep)[-1]
        
        # On remplace l'extension dans le champ image
        old_rel_path = p.image.name
        new_rel_path = os.path.splitext(old_rel_path)[0] + ".png"
        
        p.image.name = new_rel_path
        p.save()
        
        print(f"Nettoyage russi pour {p.nom} -> {new_rel_path}")

if __name__ == "__main__":
    clean_all_products()
