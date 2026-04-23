# Lunette Pro — Plateforme de gestion optique

Application web complète de gestion optique permettant aux clients d'acheter des lunettes en ligne, aux opticiens de gérer leur boutique, et aux administrateurs de superviser la plateforme.

---

## Table des matières

1. [Fonctionnalités](#1-fonctionnalités)
2. [Architecture du projet](#2-architecture-du-projet)
3. [Logiciels à installer](#3-logiciels-à-installer)
4. [Cloner le projet](#4-cloner-le-projet)
5. [Configurer la base de données](#5-configurer-la-base-de-données)
6. [Configurer le backend Django](#6-configurer-le-backend-django)
7. [Configurer le frontend React](#7-configurer-le-frontend-react)
8. [Lancer le projet](#8-lancer-le-projet)
9. [Rôles et accès](#9-rôles-et-accès)
10. [Problèmes fréquents](#10-problèmes-fréquents)

---

## 1. Fonctionnalités

### Authentification *(tous les rôles)*
- Inscription avec choix du rôle (Client ou Opticien)
- Connexion par email + mot de passe avec tokens JWT
- Modification du mot de passe
- Vérification par OTP via SMS

---

### Catalogue de montures *(Client)*
- Parcours du catalogue avec filtres avancés : catégorie (adulte, enfant, sport, luxe), forme (ronde, carrée, rectangulaire, ovale), couleur, fourchette de prix
- Fiche détaillée avec galerie d'images, spécifications techniques et informations du vendeur
- Indicateurs de disponibilité en stock en temps réel

---

### Essai virtuel *(Client)*
- Essayage en temps réel via la caméra de l'appareil
- Superposition de la monture sur le visage via rendu canvas
- Rendu adapté à la forme de la monture (ronde, carrée, rectangulaire, ovale)
- Capture et sauvegarde de photos

---

### Ordonnances *(Client)*
- Upload d'une ordonnance au format image ou PDF
- Extraction automatique des données par OCR/IA : OD/OG (sphère, cylindre, axe), nom du médecin
- Validation et sélection de l'ordonnance lors du passage de commande

---

### Commandes *(Client + Opticien)*
**Client :**
- Passer une commande avec sélection de la monture, ordonnance, assurance, adresse de livraison et moyen de paiement (Orange Money, Wave, Carte bancaire)
- Application de codes promo et réductions famille
- Suivi en temps réel des commandes avec statuts détaillés : en attente, validée, en préparation, expédiée, livrée, rejetée, annulée
- Annulation d'une commande en attente

**Opticien :**
- Réception et gestion des commandes entrantes
- Mise à jour des statuts avec notes internes
- Notifications email automatiques envoyées aux clients à chaque changement de statut

---

### Assurance *(Client + Admin)*
**Client :**
- Sélection de sa compagnie d'assurance et saisie du numéro de police dans le profil
- Simulation du montant de remboursement avant la commande

**Admin :**
- Création et gestion des compagnies d'assurance (nom, code, taux de remboursement en %, plafond annuel optionnel)
- Activation / désactivation des compagnies

---

### Groupes familiaux *(Client)*
- Création d'un groupe familial avec génération d'un code d'invitation unique
- Rejoindre un groupe existant via le code
- Réduction automatique appliquée lors des commandes pour les membres du groupe
- Invitation de membres supplémentaires par email

---

### Publications & Communauté *(Client)*
- Création de publications avec titre, contenu et image optionnelle
- Système de likes et de commentaires
- Fil d'actualité de la communauté optique

---

### Gestion de la boutique *(Opticien)*
- Modification des informations de la boutique : nom, adresse, téléphone, description
- Upload et mise à jour du logo
- Profil public visible par les clients

---

### Gestion des montures *(Opticien)*
- Ajout, modification et suppression de montures avec upload de plusieurs images
- Gestion du stock avec historique des ajustements (quantité, motif)
- Alertes visuelles : stock faible (orange ≤ 3 unités), rupture de stock (rouge)

---

### Marketing & CRM *(Opticien)*
- Liste des clients ayant un anniversaire ce mois-ci avec envoi de vœux
- Segmentation de la clientèle
- Envoi de SMS marketing en masse par segment
- Suivi des campagnes marketing

---

### Statistiques & Tableaux de bord *(Opticien + Admin)*
**Opticien :**
- Nombre de commandes totales et en attente, montures en vente, chiffre d'affaires

**Admin :**
- Vue globale : nombre de clients, opticiens, commandes, montures, revenus totaux
- Répartition des commandes par statut

---

### Gestion des utilisateurs *(Admin)*
- Liste, recherche et filtrage des utilisateurs par rôle (client, opticien, admin)
- Activation / désactivation de comptes
- Suppression d'utilisateurs et de boutiques associées

---

### Maintenance *(Admin)*
- Activation / désactivation du mode maintenance avec message personnalisé
- Historique complet des événements de maintenance
- Sauvegarde de la base de données

---

## 2. Architecture du projet

```
Lunette-project/
├── backend/                      ← API Django (backend)
│   ├── users/                    ← Comptes et authentification
│   ├── montures/                 ← Catalogue de montures
│   ├── commandes/                ← Gestion des commandes
│   ├── ordonnances/              ← Upload et lecture OCR d'ordonnances
│   ├── essai_virtuel/            ← Essai virtuel via webcam
│   ├── config/                   ← Paramètres Django (settings, urls)
│   ├── requirements.txt          ← Dépendances Python
│   └── .env                      ← Variables secrètes (à créer)
└── frontend/                     ← Interface React (Vite + Tailwind)
    └── src/
        ├── pages/                ← Toutes les pages (client, opticien, admin)
        ├── lib/api.ts            ← Appels vers le backend (Axios)
        └── contexts/             ← Session utilisateur (JWT)
```

**Stack technique :**

| Côté | Technologie |
|---|---|
| Frontend | React 18 + TypeScript + Vite |
| Styles | Tailwind CSS |
| Backend | Django + Django REST Framework |
| Auth | JWT (SimpleJWT) |
| Base de données | PostgreSQL |
| OCR | Tesseract + OpenCV |

---

## 3. Logiciels à installer

Installe-les dans l'ordre. Tous les liens pointent vers des versions Windows.

### Python 3.11 ou 3.12

Télécharge sur https://www.python.org/downloads/

> **Important :** lors de l'installation, coche **"Add Python to PATH"** avant de cliquer sur Installer.

Vérifie :
```cmd
python --version
```
Tu dois voir `Python 3.11.x` ou `Python 3.12.x`.

---

### Node.js 20 LTS

Télécharge sur https://nodejs.org/ (choisis la version **LTS**).

Vérifie :
```cmd
node --version
npm --version
```

---

### PostgreSQL 16

Télécharge sur https://www.enterprisedb.com/downloads/postgres-postgresql-downloads

Lors de l'installation :
- Note le **mot de passe** du superutilisateur (`postgres`) — tu en auras besoin
- Laisse le port à `5432`

Vérifie :
```cmd
psql --version
```

---

### Tesseract OCR

Télécharge l'installateur Windows sur https://github.com/UB-Mannheim/tesseract/wiki

> Note le chemin d'installation. Par défaut : `C:\Program Files\Tesseract-OCR\tesseract.exe`  
> Lors de l'installation, coche le pack de langue **French** dans la liste des langues supplémentaires.

---

### Git

Télécharge sur https://git-scm.com/download/win. Laisse toutes les options par défaut.

Vérifie :
```cmd
git --version
```

---

## 4. Cloner le projet

Ouvre l'**Invite de commandes** ou **PowerShell** et exécute :

```cmd
git clone <URL_DU_DEPOT> Lunette-project
cd Lunette-project
```

> Remplace `<URL_DU_DEPOT>` par l'URL GitHub du projet.

---

## 5. Configurer la base de données

### Créer la base PostgreSQL

Ouvre un terminal et connecte-toi avec le superutilisateur :

```cmd
psql -U postgres
```

Entre le mot de passe défini à l'installation, puis exécute ces commandes :

```sql
CREATE DATABASE lunettes_db;
\q
```

---

## 6. Configurer le backend Django

### 5.1 Se placer dans le bon dossier

```cmd
cd backend
```

### 5.2 Créer un environnement virtuel Python

```cmd
python -m venv venv
```

### 5.3 Activer l'environnement virtuel

```cmd
venv\Scripts\activate
```

> Le préfixe `(venv)` apparaît dans le terminal. **Tu dois toujours l'activer avant de travailler sur le backend.**

### 5.4 Installer les dépendances Python

```cmd
pip install -r requirements.txt
```

### 5.5 Créer le fichier `.env`

Dans le dossier `SubGroupOne-django-backend/`, crée un fichier nommé `.env` (sans extension) avec ce contenu :

```env
SECRET_KEY=remplace-par-une-longue-cle-aleatoire
DEBUG=True

DB_NAME=lunettes_db
DB_USER=postgres
DB_PASSWORD=ton_mot_de_passe_postgres
DB_HOST=localhost
DB_PORT=5432

TESSERACT_PATH=C:\Program Files\Tesseract-OCR\tesseract.exe
```

> - Remplace `ton_mot_de_passe_postgres` par le mot de passe choisi à l'étape 2.
> - Si Tesseract est installé ailleurs, adapte le chemin `TESSERACT_PATH`.

### 5.6 Appliquer les migrations

```cmd
python manage.py migrate
```

Tu dois voir une liste de lignes se terminant par `OK`.

### 5.7 Créer un compte administrateur

```cmd
python manage.py createsuperuser
```

Suis les instructions (nom d'utilisateur, email, mot de passe). Note ces informations.

### 5.8 Lancer le serveur backend

```cmd
python manage.py runserver
```

Le backend tourne sur **http://localhost:8000**  
L'interface d'administration est disponible sur **http://localhost:8000/admin**

> Ne ferme pas ce terminal. Ouvre-en un nouveau pour le frontend.

---

## 7. Configurer le frontend React

### 6.1 Ouvrir un nouveau terminal dans le dossier frontend

```cmd
cd Lunette-project\frontend
```

### 6.2 Créer le fichier `.env`

Dans le dossier `frontend/`, crée un fichier `.env` avec ce contenu :

```env
VITE_API_URL=http://localhost:8000/api
```

### 6.3 Installer les dépendances JavaScript

```cmd
npm install
```

> Peut prendre 2 à 5 minutes la première fois.

### 6.4 Lancer le serveur frontend

```cmd
npm run dev
```

Le frontend est accessible sur **http://localhost:5173**

---

## 8. Lancer le projet

Chaque fois que tu veux utiliser le projet, ouvre **deux terminaux** :

**Terminal 1 — Backend :**
```cmd
cd Lunette-project\backend
venv\Scripts\activate
python manage.py runserver
```

**Terminal 2 — Frontend :**
```cmd
cd Lunette-project\frontend
npm run dev
```

Ouvre ensuite **http://localhost:5173** dans ton navigateur.

---

## 9. Rôles et accès

Il y a trois types de comptes :

| Rôle | Accès |
|---|---|
| **Client** | Catalogue, commandes, ordonnances, essai virtuel, profil |
| **Opticien** | Gestion des montures, traitement des commandes, boutique |
| **Admin** | Gestion des utilisateurs, tableau de bord, statistiques |

**Créer des comptes de test :**

- **Via l'application** → http://localhost:5173/register (crée un compte `client` par défaut)
- **Via l'admin Django** → http://localhost:8000/admin → Users → changer le champ `role`
- Le compte `superuser` créé à l'étape 5.7 peut se connecter directement sur l'app

---

## 10. Problèmes fréquents

### `python` n'est pas reconnu

Python n'est pas dans le PATH Windows.
- Désinstalle Python
- Réinstalle en cochant **"Add Python to PATH"**

### `psql` n'est pas reconnu

Ajoute le dossier `bin` de PostgreSQL aux variables d'environnement Windows :
- Chemin habituel : `C:\Program Files\PostgreSQL\16\bin`
- Cherche "Variables d'environnement" dans le menu Démarrer → ajoute ce chemin à `PATH`

### Erreur de connexion à la base de données

```
django.db.utils.OperationalError: could not connect to server
```

PostgreSQL n'est pas démarré.
- Win+R → `services.msc` → cherche `postgresql-x64-16` → clic droit → **Démarrer**

### Mauvais mot de passe PostgreSQL

```
FATAL: password authentication failed for user "postgres"
```

- Reconnecte-toi : `psql -U postgres`
- Change le mot de passe : `ALTER USER postgres WITH PASSWORD 'nouveau_mot_de_passe';`
- Mets à jour `DB_PASSWORD` dans le fichier `.env`

### Erreur `ModuleNotFoundError`

Une dépendance manque ou le venv n'est pas activé.
- Vérifie que `(venv)` apparaît dans le terminal
- Relance : `pip install <nom_du_module>`

### Erreur Tesseract (`tesseract is not installed`)

Le chemin vers Tesseract dans `.env` est incorrect.
- Trouve `tesseract.exe` sur ton ordinateur (généralement dans `C:\Program Files\Tesseract-OCR\`)
- Mets à jour `TESSERACT_PATH` dans `.env` avec le chemin exact

### Port 8000 déjà utilisé

```cmd
netstat -ano | findstr :8000
taskkill /PID <numero_affiché> /F
```

### Le frontend ne peut pas appeler le backend (erreur réseau)

- Vérifie que le backend tourne bien sur le port 8000
- Vérifie que `frontend/.env` contient `VITE_API_URL=http://localhost:8000/api`
- Redémarre le frontend après toute modification du `.env`
