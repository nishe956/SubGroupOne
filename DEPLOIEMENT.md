# Déploiement sur des plateformes gratuites

Guide de mise en production d'OptiLunette : API Django + SPA React, sans aucun
coût d'hébergement. Compter environ une heure pour un premier déploiement.

> Les quotas cités sont ceux constatés à la rédaction (août 2026). Les offres
> gratuites changent souvent : vérifier chaque limite au moment du déploiement.

---

## 1. Architecture retenue

| Brique | Plateforme | Offre gratuite | Limite à connaître |
|---|---|---|---|
| API Django | **Render** (Docker) | 512 Mo RAM, 750 h/mois | Mise en veille après 15 min sans trafic ; réveil en 30–60 s |
| Base PostgreSQL | **Neon** | 0,5 Go | Suspension auto après 5 min ; première requête ralentie |
| Cache partagé | **Redis Cloud** | 30 Mo, 30 connexions | Obligatoire : l'API refuse de démarrer sans lui |
| Médias | **Cloudflare R2** | 10 Go, egress gratuit | Deux buckets requis (public + privé) |
| SPA React | **Cloudflare Pages** | illimité, usage commercial autorisé | — |

### Pourquoi Cloudflare Pages plutôt que Vercel

`frontend/vercel.json` est prêt et Vercel fonctionne parfaitement — mais **l'offre
Hobby de Vercel interdit l'usage commercial**. Une boutique qui vend des montures
en ligne sort du cadre. Cloudflare Pages (ou Netlify) n'a pas cette restriction.

Les deux chemins sont supportés : `frontend/public/_headers` et
`frontend/public/_redirects` reproduisent pour Cloudflare/Netlify ce que
`vercel.json` fait pour Vercel. **Si vous modifiez la CSP, modifiez les deux.**

---

## 2. Base de données — Neon

1. [neon.tech](https://neon.tech) → **New Project**, région *Europe (Frankfurt)*.
2. Copier les identifiants de la chaîne de connexion :
   `postgresql://<DB_USER>:<DB_PASSWORD>@<DB_HOST>/<DB_NAME>?sslmode=require`
3. Utiliser l'endpoint **pooled** (`-pooler` dans le nom d'hôte) : l'offre gratuite
   plafonne les connexions directes, et Django en garde une ouverte 60 s
   (`DB_CONN_MAX_AGE`).

---

## 3. Cache — Redis Cloud

1. [redis.com/try-free](https://redis.com/try-free) → base **Free 30 Mo**, même région.
2. Récupérer `REDIS_URL` au format `redis://default:<mot_de_passe>@<hôte>:<port>`.

> **Upstash** convient aussi, mais son offre gratuite plafonne à 10 000 commandes
> par jour. La limitation de débit DRF consomme ~4 commandes par requête HTTP,
> soit un plafond effectif d'environ 2 500 requêtes quotidiennes. Redis Cloud
> n'impose pas de compteur journalier : c'est le choix le plus sûr ici.

---

## 4. Médias — Cloudflare R2

Deux buckets, **séparation non négociable** : les ordonnances sont des données de
santé et ne doivent jamais atterrir dans le bucket public du catalogue. Le code
refuse d'ailleurs de démarrer si le bucket privé manque alors que le public existe.

1. Dashboard Cloudflare → **R2** → créer :
   - `lunette-media` — **public**, activer le sous-domaine `r2.dev` ;
   - `lunette-documents-prives` — **privé**, aucun accès public, aucun domaine.
2. **R2 → Manage API Tokens** → *Create token*, permission *Object Read & Write*
   sur les deux buckets. Noter la clé et le secret (affichés une seule fois).
3. Relever `AWS_S3_ENDPOINT_URL` : `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`
   et `AWS_S3_CUSTOM_DOMAIN` : le `pub-xxxxxxxx.r2.dev` du bucket **public**.

---

## 5. API — Render

Le dépôt contient `render.yaml` : Render lit ce fichier et ne demande
que les secrets.

1. [render.com](https://render.com) → **Blueprints** → *New Blueprint Instance*,
   sélectionner le dépôt.
2. Render affiche les variables marquées `sync: false`. Les renseigner :

   ```
   SECRET_KEY               (voir ci-dessous)
   ALLOWED_HOSTS            lunette-api.onrender.com
   CORS_ALLOWED_ORIGINS     https://optilunette.pages.dev
   CSRF_TRUSTED_ORIGINS     https://optilunette.pages.dev
   FRONTEND_URL             https://optilunette.pages.dev
   DB_NAME / DB_USER / DB_PASSWORD / DB_HOST      (Neon, étape 2)
   REDIS_URL                                      (Redis Cloud, étape 3)
   AWS_*                                          (R2, étape 4)
   ADMIN_URL                gestion-interne-8f3a/
   ```

   Générer la clé secrète — l'application refuse toute clé de moins de
   50 caractères ou contenant « insecure », « change », « default » :

   ```bash
   python -c "from django.core.management.utils import get_random_secret_key as g; print(g()+g())"
   ```

3. Premier build : 10 à 15 minutes (MediaPipe et OpenCV pèsent lourd).
4. **Migrations** — depuis votre machine, pas depuis Render.

   L'onglet *Shell* de Render est réservé aux offres payantes. Or Neon est
   joignable depuis n'importe où : on applique donc les migrations en local, en
   pointant Django sur la base de production. C'est aussi plus sûr — vous voyez
   le plan de migration avant qu'il ne s'exécute.

   ```bash
   cd backend && source .venv/bin/activate

   # Endpoint DIRECT de Neon (sans « -pooler ») : le pooler de Neon est en mode
   # transaction, incompatible avec les verrous que prend une migration.
   export DEBUG=True SECRET_KEY=valeur-locale-sans-importance
   export DB_NAME=... DB_USER=... DB_PASSWORD=... DB_PORT=5432 DB_SSLMODE=require
   export DB_HOST=ep-xxxx.eu-central-1.aws.neon.tech

   python manage.py migrate --plan      # à lire avant d'appliquer
   python manage.py migrate --noinput
   python manage.py createsuperuser
   ```

   `RUN_MIGRATIONS` reste à `0` sur Render : jouées au démarrage du conteneur,
   deux instances les appliqueraient en parallèle et une migration destructrice
   passerait sans validation humaine.

5. Vérifier : `curl https://lunette-api.onrender.com/healthz/` doit renvoyer `ok`.

---

## 6. SPA — Cloudflare Pages

1. Cloudflare → **Workers & Pages** → *Create* → *Pages* → connecter le dépôt.
2. Réglages de build :

   | Champ | Valeur |
   |---|---|
   | Répertoire racine | `frontend` |
   | Commande de build | `npm run build` |
   | Répertoire de sortie | `dist` |

3. Variables d'environnement (*Production*) :

   ```
   VITE_API_URL           https://lunette-api.onrender.com/api
   VITE_GOOGLE_CLIENT_ID  <votre client id>.apps.googleusercontent.com
   VITE_MEDIA_BASE        (laisser vide)
   ```

   `VITE_MEDIA_BASE` reste vide dès que R2 est configuré : Django renvoie déjà
   des URLs absolues vers `r2.dev`. Ne la renseigner que si les médias sont
   servis par l'hôte Django.

4. Une fois l'URL Pages connue, revenir sur Render corriger `CORS_ALLOWED_ORIGINS`,
   `CSRF_TRUSTED_ORIGINS` et `FRONTEND_URL`, puis redéployer.

---

## 7. Google OAuth

Google Cloud Console → *Identifiants* → client OAuth Web :

- **Origines JavaScript autorisées** : `https://optilunette.pages.dev`
- **URI de redirection** : `https://optilunette.pages.dev`

Reporter le client ID dans `VITE_GOOGLE_CLIENT_ID` (Pages) **et**
`GOOGLE_CLIENT_ID` (Render) — le backend vérifie l'audience du jeton.

---

## 8. Tâches planifiées

`RUN_SCHEDULER` reste à `0`. L'ordonnanceur APScheduler intégré suppose un
process qui tourne en continu ; sur une instance mise en veille après 15 minutes,
les SMS d'anniversaire ne partiraient jamais.

La commande dédiée est appelable depuis n'importe quel cron externe :

```bash
python manage.py envoyer_anniversaires
```

Elle est idempotente sur la journée — `HistoriqueSMS` enregistre chaque envoi par
client et par jour — donc une double exécution n'envoie ni ne facture deux SMS.

**GitHub Actions** (gratuit), `.github/workflows/anniversaires.yml` :

```yaml
name: SMS anniversaires
on:
  schedule:
    - cron: '0 8 * * *'      # 08:00 UTC — la planification GitHub peut dériver de quelques minutes
  workflow_dispatch:
jobs:
  reveiller:
    runs-on: ubuntu-latest
    steps:
      # Réveille l'instance Render, endormie faute de trafic.
      - run: curl -fsS --retry 5 --retry-all-errors --retry-delay 20 https://lunette-api.onrender.com/healthz/
```

Le déclenchement de la tâche elle-même demande soit le Shell Render, soit un
endpoint protégé à ajouter. Le plus simple aujourd'hui : un rappel manuel, ou
passer l'instance sur une offre payante avec cron intégré.

---

## 9. Vérifications après déploiement

```bash
API=https://lunette-api.onrender.com

curl -s $API/healthz/                        # → ok
curl -s -o /dev/null -w '%{http_code}\n' $API/api/maintenance/statut/   # → 200
curl -s -o /dev/null -w '%{http_code}\n' $API/admin/                    # → 404 (ADMIN_URL modifié)
```

Puis, dans le navigateur : créer un compte, téléverser une ordonnance, vérifier
qu'elle **n'est pas** accessible par URL directe, passer une commande, se
connecter en admin sur `https://.../gestion-interne-8f3a/`.

---

## 10. Limites réelles de la version gratuite

| Symptôme | Cause | Contournement |
|---|---|---|
| Première visite très lente (30–60 s) | Instance Render en veille | Un ping régulier la garde éveillée ; sinon offre payante |
| Essai virtuel lent ou en échec | MediaPipe sur 0,1 vCPU et 512 Mo | 1 seul worker (déjà configuré) ; éviter les essais simultanés |
| `502` sporadique sous charge | OOM du conteneur | Ne pas augmenter `GUNICORN_WORKERS` |
| Base indisponible quelques secondes | Reprise après suspension Neon | Comportement normal de l'offre |
| Envoi de SMS inopérant | Identifiants Orange absents | Renseigner les variables `ORANGE_*` |

**Ces offres conviennent à une démonstration, une recette ou un pilote.** Pour
une exploitation commerciale réelle, le premier poste à financer est l'instance
Render (~7 $/mois) : il supprime d'un coup la mise en veille, la limite mémoire
et le besoin de cron externe.
