# Smart Vision - Backend API

Backend de l'application de vente de verres correcteurs avec essai virtuel.

## Technologies utilisées
- Django 5.x
- Django REST Framework
- PostgreSQL
- JWT Authentication

## Installation

### 1. Cloner le projet
```
git clone https://github.com/nishe956/SubGroupOne
cd SubGroupOne
```

### 2. Créer l'environnement virtuel
```
py -3.12 -m venv env
env\Scripts\activate
```

### 3. Installer les dépendances
```
pip install -r requirements.txt
```

### 4. Configurer le fichier .env
Crée un fichier `.env` avec ces variables :
```
SECRET_KEY=ta_cle_secrete
DEBUG=True
DB_NAME=lunettes_db
DB_USER=postgres
DB_PASSWORD=ton_mot_de_passe
DB_HOST=localhost
DB_PORT=5432
```

### 5. Créer la base de données
Dans pgAdmin, crée une base de données nommée `lunettes_db`

### 6. Appliquer les migrations
```
python manage.py migrate
```

### 7. Lancer le serveur
```
python manage.py runserver
```

## Routes API principales
| Route | Méthode | Description |
|---|---|---|
| /api/users/register/ | POST | Inscription |
| /api/users/login/ | POST | Connexion |
| /api/montures/ | GET | Liste montures |
| /api/commandes/passer/ | POST | Passer commande |