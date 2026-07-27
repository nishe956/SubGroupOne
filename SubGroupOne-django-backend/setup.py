import os

# Crée les fichiers __init__.py vides
files = [
    'users/__init__.py',
    'montures/__init__.py',
    'commandes/__init__.py',
    'ordonnances/__init__.py',
    'users/migrations/__init__.py',
    'montures/migrations/__init__.py',
    'commandes/migrations/__init__.py',
    'ordonnances/migrations/__init__.py',
]
for f in files:
    open(f, 'w').close()
    print(f'Cree: {f}')

# Crée les apps.py
apps = {
    'users/apps.py': '''from django.apps import AppConfig

class UsersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'users'
''',
    'montures/apps.py': '''from django.apps import AppConfig

class MonturesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'montures'
''',
    'commandes/apps.py': '''from django.apps import AppConfig

class CommandesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'commandes'
''',
    'ordonnances/apps.py': '''from django.apps import AppConfig

class OrdonnancesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'ordonnances'
''',
}

for path, content in apps.items():
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Cree: {path}')

print('Tous les fichiers ont ete crees !')
# Ajoute à la fin de setup.py
files_essai = [
    'essai_virtuel/__init__.py',
    'essai_virtuel/migrations/__init__.py',
]
for f in files_essai:
    open(f, 'w').close()
    print(f'Cree: {f}')