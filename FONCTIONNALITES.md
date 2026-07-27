# OptiLunette — Fonctionnalités

Plateforme web de gestion optique avec trois types d'utilisateurs : **Client**, **Opticien** et **Admin**.

---

## Authentification

- Inscription avec choix du rôle (Client ou Opticien)
- Connexion par email + mot de passe
- Déconnexion sécurisée
- Modification du mot de passe depuis le profil
- Vérification d'identité par code OTP envoyé par SMS

---

## Espace Client

### Catalogue de montures
- Parcours de l'ensemble des montures disponibles
- Filtres avancés : catégorie (adulte, enfant, sport, luxe), forme (ronde, carrée, rectangulaire, ovale), couleur, fourchette de prix
- Barre de recherche par nom ou marque
- Indicateur de disponibilité en stock sur chaque monture

### Fiche monture
- Galerie d'images de la monture
- Spécifications techniques (forme, couleur, marque, catégorie, prix)
- Informations du vendeur (boutique, contact)
- Bouton de commande directe

### Essai virtuel
- Essayage en temps réel via la caméra de l'appareil
- Superposition de la monture sur le visage
- Rendu adapté à la forme de chaque monture
- Capture et sauvegarde d'une photo de l'essayage

### Ordonnances
- Upload d'une ordonnance (image ou PDF)
- Extraction automatique des données par intelligence artificielle : œil droit/gauche, sphère, cylindre, axe, nom du médecin
- Historique des ordonnances uploadées
- Sélection d'une ordonnance lors du passage de commande

### Commandes
- Passage de commande avec sélection de : monture, ordonnance, assurance, adresse de livraison, moyen de paiement (Orange Money, Wave, Carte bancaire)
- Application de codes promo et réductions groupe familial
- Simulation du remboursement assurance avant validation
- Suivi des commandes avec statuts : en attente, validée, en préparation, expédiée, livrée, rejetée, annulée
- Annulation d'une commande encore en attente

### Assurance
- Sélection de sa compagnie d'assurance dans le profil
- Saisie du numéro de police
- Simulation du montant remboursé avant de commander

### Groupes familiaux
- Création d'un groupe familial avec génération d'un code d'invitation
- Rejoindre un groupe existant via le code
- Invitation de membres supplémentaires par email
- Réduction automatique appliquée sur les commandes pour tous les membres du groupe

### Publications & Communauté
- Création de publications avec titre, contenu et image
- Consultation du fil d'actualité de la communauté
- Liker et commenter les publications

### Profil
- Modification des informations personnelles : prénom, nom, téléphone, adresse, date de naissance
- Changement du mot de passe
- Gestion des informations d'assurance

---

## Espace Opticien

### Gestion de la boutique
- Modification des informations de la boutique : nom, adresse, téléphone, description
- Upload et mise à jour du logo
- Profil public visible par les clients

### Gestion des montures
- Ajout de nouvelles montures avec : nom, marque, catégorie, forme, couleur, prix, stock, images
- Modification et suppression de montures existantes
- Upload de plusieurs images par monture

### Gestion du stock
- Ajustement du stock d'une monture (quantité + motif)
- Historique des mouvements de stock
- Alertes visuelles : stock faible (orange, ≤ 3 unités) et rupture de stock (rouge)

### Gestion des commandes
- Réception des commandes passées par les clients
- Filtrage des commandes par statut
- Mise à jour du statut d'une commande avec notes internes
- Notification email automatique envoyée au client à chaque changement de statut

### Marketing & CRM
- Liste des clients ayant un anniversaire ce mois-ci
- Envoi de vœux d'anniversaire aux clients
- Segmentation de la clientèle
- Envoi de SMS marketing en masse par segment
- Suivi des campagnes marketing

### Statistiques
- Nombre total de commandes et commandes en attente
- Nombre de montures en vente
- Chiffre d'affaires (commandes livrées)
- Aperçu des dernières commandes reçues

---

## Espace Admin

### Gestion des utilisateurs
- Liste complète des utilisateurs avec recherche et filtrage par rôle
- Activation et désactivation de comptes
- Suppression d'un utilisateur (et de sa boutique si opticien)
- Création directe de comptes opticien

### Gestion des assurances
- Création de compagnies d'assurance avec taux de remboursement (%) et plafond annuel
- Activation / désactivation des compagnies
- Traitement des demandes de remboursement

### Statistiques globales
- Nombre total de clients, opticiens, commandes, montures et revenus
- Répartition des commandes par statut

### Maintenance
- Activation du mode maintenance avec message personnalisé
- Désactivation du mode maintenance
- Historique des événements de maintenance
- Sauvegarde de la base de données

---

## Récapitulatif par rôle

| Fonctionnalité | Client | Opticien | Admin |
|---|:---:|:---:|:---:|
| Catalogue & fiche monture | ✓ | ✓ | ✓ |
| Essai virtuel | ✓ | | |
| Ordonnances | ✓ | | |
| Passer une commande | ✓ | | |
| Gérer les commandes reçues | | ✓ | ✓ |
| Assurance (sélection & simulation) | ✓ | | |
| Assurance (gestion compagnies) | | | ✓ |
| Groupes familiaux | ✓ | | |
| Publications & communauté | ✓ | | |
| Gestion boutique | | ✓ | |
| Gestion montures & stock | | ✓ | ✓ |
| Marketing & CRM | | ✓ | |
| Statistiques | | ✓ | ✓ |
| Gestion des utilisateurs | | | ✓ |
| Maintenance & sauvegarde | | | ✓ |
