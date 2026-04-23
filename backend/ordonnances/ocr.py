import os
import base64
import json
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()


def analyser_ordonnance(image_path: str) -> dict:
    """
    Envoie l'image à Groq Vision et extrait les valeurs optiques.
    """
    api_key = os.getenv('GROQ_API_KEY')
    if not api_key:
        return {'succes': False, 'erreur': 'GROQ_API_KEY manquante dans .env', 'valeurs_optiques': None}

    try:
        with open(image_path, 'rb') as f:
            image_data = base64.b64encode(f.read()).decode('utf-8')
    except Exception as e:
        return {'succes': False, 'erreur': f'Impossible de lire l\'image : {e}', 'valeurs_optiques': None}

    ext = os.path.splitext(image_path)[1].lower()
    mime_types = {'.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp'}
    mime = mime_types.get(ext, 'image/jpeg')

    client = OpenAI(
        api_key=api_key,
        base_url='https://api.groq.com/openai/v1',
    )

    prompt = """Tu es un assistant spécialisé dans la lecture d'ordonnances optiques.
Analyse cette image et extrait les valeurs optiques.

Retourne UNIQUEMENT un JSON valide avec cette structure exacte (null si la valeur n'est pas présente) :
{
  "oeil_droit_sphere": <nombre ou null>,
  "oeil_droit_cylindre": <nombre ou null>,
  "oeil_droit_axe": <nombre ou null>,
  "oeil_gauche_sphere": <nombre ou null>,
  "oeil_gauche_cylindre": <nombre ou null>,
  "oeil_gauche_axe": <nombre ou null>
}

Notes :
- OD / Oeil Droit / Right Eye / RE = oeil_droit
- OG / Oeil Gauche / Left Eye / LE = oeil_gauche
- Sph / Sphere = sphere
- Cyl / Cylindre = cylindre
- Axe = axe (valeur entre 0 et 180)
- Les valeurs de sphère et cylindre peuvent être positives (+) ou négatives (-)
- Retourne uniquement le JSON, sans texte autour."""

    try:
        response = client.chat.completions.create(
            model='meta-llama/llama-4-scout-17b-16e-instruct',
            messages=[
                {
                    'role': 'user',
                    'content': [
                        {
                            'type': 'image_url',
                            'image_url': {
                                'url': f'data:{mime};base64,{image_data}',
                            },
                        },
                        {
                            'type': 'text',
                            'text': prompt,
                        },
                    ],
                }
            ],
            max_tokens=300,
        )

        texte = response.choices[0].message.content.strip()

        if texte.startswith('```'):
            texte = texte.split('```')[1]
            if texte.startswith('json'):
                texte = texte[4:]

        valeurs = json.loads(texte)

        return {
            'succes': True,
            'valeurs_optiques': {
                'oeil_droit_sphere':    valeurs.get('oeil_droit_sphere'),
                'oeil_droit_cylindre':  valeurs.get('oeil_droit_cylindre'),
                'oeil_droit_axe':       valeurs.get('oeil_droit_axe'),
                'oeil_gauche_sphere':   valeurs.get('oeil_gauche_sphere'),
                'oeil_gauche_cylindre': valeurs.get('oeil_gauche_cylindre'),
                'oeil_gauche_axe':      valeurs.get('oeil_gauche_axe'),
            }
        }

    except json.JSONDecodeError as e:
        return {'succes': False, 'erreur': f'Réponse non parseable : {e}', 'valeurs_optiques': None}
    except Exception as e:
        return {'succes': False, 'erreur': str(e), 'valeurs_optiques': None}
