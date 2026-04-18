import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model
from montures.models import Monture

User = get_user_model()

def seed_data():
    # 1. Create Superuser
    if not User.objects.filter(email='admin@lunettes.com').exists():
        print("Creating superuser...")
        User.objects.create_superuser(
            username='admin',
            email='admin@lunettes.com',
            password='adminpassword',
            first_name='Admin',
            last_name='User'
        )
        print("Superuser created: admin@lunettes.com / adminpassword")
    else:
        print("Superuser already exists.")

    # 2. Add some products
    if Monture.objects.count() == 0:
        print("Seeding products...")
        products = [
            {
                'nom': 'Studio Silver',
                'marque': 'Carrées',
                'prix': 410.00,
                'forme': 'carree',
                'genre': 'unisexe',
                'couleur': 'Argent',
                'description': 'Monture optique carrée adoucie, pont fin et verres clairs.'
            },
            {
                'nom': 'Stella',
                'marque': 'Solaire Œil de Chat',
                'prix': 465.00,
                'forme': 'ovale',
                'genre': 'femme',
                'couleur': 'Rose Gold',
                'description': 'Grand solaire cat-eye, métal rose gold.'
            },
            {
                'nom': 'Harmonie Dorée',
                'marque': 'Rondes',
                'prix': 520.00,
                'forme': 'ronde',
                'genre': 'homme',
                'couleur': 'Or',
                'description': 'Monture percée légère, pont et temples or poli.'
            },
            {
                'nom': 'Icône',
                'marque': 'Cat-Eye Tortoise',
                'prix': 430.00,
                'forme': 'rectangulaire',
                'genre': 'femme',
                'couleur': 'Écaille',
                'description': 'Écaille chaude narrow vintage.'
            }
        ]
        
        for p in products:
            Monture.objects.create(**p)
        print(f"Added {len(products)} products.")
    else:
        print("Products already exist in database.")

if __name__ == "__main__":
    seed_data()
