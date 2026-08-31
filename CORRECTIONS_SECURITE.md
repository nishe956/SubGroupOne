# Corrections de sécurité — Lunette-project / OptiLunette

**Date :** 2026-08-25 · **Référence :** `AUDIT_SECURITE.md`
**Portée :** les 43 points de l'audit ont été traités dans le code. Ce document
liste ce qui a été fait, puis **ce qui reste à faire manuellement** — des actions
qui ne peuvent pas être réalisées depuis le dépôt.

---

## ⚠️ À FAIRE IMMÉDIATEMENT (hors dépôt)

Ces cinq actions conditionnent tout le reste. Tant qu'elles ne sont pas faites,
les corrections de code ne protègent pas la production.

### 1. Révoquer et régénérer les secrets exposés (V08)

Ces valeurs sont restées en clair sur disque et doivent être considérées comme
compromises :

| Secret | Où | Action |
|---|---|---|
| Clé API Groq  | `backend/.env` + fichier `api_groq` (supprimé) | Révoquer dans la console Groq, régénérer |
| Mot de passe d'application Gmail | `backend/.env` | Révoquer dans Google → Sécurité → Mots de passe d'application |
| Mot de passe PostgreSQL | `backend/.env` | Changer sur Neon / le serveur |
| `SECRET_KEY` | historique Git | ✅ régénérée localement — **en générer une différente pour la production** |

La `SECRET_KEY` de développement a déjà été régénérée dans `backend/.env`. La
production doit avoir la sienne, injectée par la plateforme, jamais dans un
fichier.

### 2. Nettoyer l'historique Git

Deux mots de passe de base de données y figurent toujours (commits `36c6f51` et
`5235185`), ainsi que l'ancienne `SECRET_KEY` :

```bash
pip install git-filter-repo
git filter-repo --path .env --path backend/.env --invert-paths --force
git push --force --all
```

Prévenir les autres contributeurs : tout clone existant conserve les secrets.
Ceux-ci restent à considérer comme définitivement compromis (point 1).

### 3. Provisionner Redis

L'application **refuse désormais de démarrer en production sans `REDIS_URL`**.
C'est délibéré : les compteurs anti-bruteforce et le mode maintenance reposent
sur un cache partagé entre les workers. Avec `LocMemCache`, la limite de 5
tentatives de connexion valait en réalité 5 × nombre de workers.

### 4. Séparer les buckets Cloudflare R2

Deux buckets sont maintenant attendus :

- `AWS_STORAGE_BUCKET_NAME` — public : photos de montures, logos ;
- `AWS_PRIVATE_BUCKET_NAME` — **privé** : ordonnances (données de santé),
  servies uniquement par URL signée de 5 minutes.

**À vérifier :** le bucket actuel `pub-xxxx.r2.dev` est-il accessible sans
authentification ? Si oui, les ordonnances déjà déposées y sont publiquement
lisibles — il faut les migrer vers le bucket privé et purger le bucket public.

### 5. Configurer les variables de déploiement

```
DEBUG=False
SECRET_KEY=<50+ caractères aléatoires>
ALLOWED_HOSTS=optilunette.bf,www.optilunette.bf
CORS_ALLOWED_ORIGINS=https://optilunette.bf
REDIS_URL=redis://…
AWS_PRIVATE_BUCKET_NAME=…
TRUST_PROXY=True
NUM_PROXIES=1          # 1 seul reverse proxy devant l'app (Render)
RUN_MIGRATIONS=0       # migrations lancées explicitement au déploiement
RUN_SCHEDULER=0        # à activer sur UNE SEULE instance
BACKUP_GPG_RECIPIENT=… # sinon l'endpoint de sauvegarde reste désactivé
```

Dans `frontend/vercel.json`, ajuster le `connect-src` de la CSP pour qu'il pointe
sur le domaine réel de l'API (les valeurs actuelles sont des jokers
`https://*.onrender.com` et `https://*.r2.dev`).

Validation : `python manage.py check --deploy` doit renvoyer **0 issue**
(vérifié en simulation).

---

## Ce qui a été corrigé

### Critiques

| # | Vulnérabilité | Correction |
|---|---|---|
| V01 | SECRET_KEY de démonstration | Contrôle de robustesse déplacé dans `config/settings.py`, appliqué dès que `DEBUG=False` : longueur ≥ 50 et rejet des motifs `insecure`/`remplace`/`change`. L'app refuse de démarrer sinon. |
| V02 | Durcissement production jamais appliqué | `settings_production.py` **supprimé** et fusionné dans `settings.py` sous `if not DEBUG:`. Source de vérité unique, impossible à oublier. |
| V03 | Lecture arbitraire de fichiers via `/media/` | `MEDIA_ROOT` défini dans **toutes** les branches ; la route `^media/` n'est montée que si `DEBUG and not AWS_STORAGE_BUCKET_NAME`. |
| V04 | Contournement du filtre ordonnances | Le chemin est normalisé (`posixpath.normpath`) **avant** comparaison aux préfixes privés — `//`, `./` et `../` ne passent plus. |
| V05 | Paiement auto-confirmé | Endpoint `paiement/confirmer/` **supprimé**. Une note dans `commandes/views.py` décrit les 5 exigences du futur webhook (signature HMAC, idempotence, contrôle du montant, machine à états). |
| V06 | Prix contrôlé par le client | Nouveau module `commandes/tarifs.py` : catalogue des verres côté serveur, rabais famille recalculé depuis la base, `Decimal` partout, plafond à 15 %, refus des totaux ≤ 0. Le client n'envoie plus que des identifiants. |
| V07 | Fraude à l'assurance | `montant_total` passé en lecture seule et repris de la commande ; contrôle de propriété, d'éligibilité et d'unicité ; remboursement plafonné au montant payé. |
| V08 | Secrets dans le dépôt | `api_groq` supprimé, `.gitignore` durci, `SECRET_KEY` de dev régénérée. **Rotation manuelle requise** (voir plus haut). |

### Importantes

- **V09 — Tokens en `localStorage`** : le jeton d'accès vit désormais en mémoire
  JavaScript uniquement ; le refresh token n'existe plus que dans un cookie
  `httpOnly` (`SameSite=None; Secure` en production). Nouvelle vue
  `RafraichirTokenView` qui lit le cookie et **refuse** un token passé dans le
  corps. Le `AuthContext` purge au démarrage les jetons laissés par l'ancienne
  version. Une file d'attente évite les rotations concurrentes.
- **V10 — Cloisonnement multi-tenant** : fonction `ordonnances_visibles()` — un
  opticien ne voit que les ordonnances rattachées à une de ses commandes.
  Idem pour commandes, historique SMS, remboursements, stock et statistiques.
- **V11/V12 — Écritures inter-opticiens** : helper `_monture_modifiable()` sur
  l'ajustement de stock et la gestion des images ; compagnies d'assurance
  réservées à `IsAdminSeulement`.
- **V13/V14 — Limitation de débit** : `NUM_PROXIES` explicite (défaut 0 →
  `REMOTE_ADDR`), nouveaux throttles par IP (`connexion`, `inscription`, `reset`,
  `otp`) qui couvrent le password spraying, incréments `cache.incr()` atomiques,
  Redis obligatoire en production.
- **V15/V16 — OTP** : numéro validé en E.164 avec liste blanche de préfixes,
  code tiré de `secrets`, **stocké haché** (HMAC-SHA256), comparaison à temps
  constant, quota par IP en plus du quota par numéro, code jamais renvoyé dans
  la réponse HTTP.
- **V16bis — Ordonnances sur R2** : stockage privé dédié, noms de fichiers
  aléatoires (`uuid4`), URL de stockage jamais exposée par le sérialiseur.
- **V17 — Révocation** : champ `User.tokens_valides_apres` +
  `JWTAuthentificationRevocable` qui compare le `iat` du jeton. Le rejet d'un
  opticien, un changement de mot de passe ou une réinitialisation coupent les
  sessions **immédiatement**, access tokens compris.
- **V18 — Race conditions** : décrément de stock atomique et conditionnel
  (`filter(stock__gt=0).update(stock=F('stock') - 1)`), annulation sous
  `select_for_update()`, le tout dans `transaction.atomic()`.
- **V19 — Backend legacy** : `SubGroupOne-django-backend/` et
  `backend-extensions/` supprimés du dépôt.
- **V20/V42 — Publications** : création réservée aux opticiens/admins, brouillon
  par défaut (`publie=False`), contrôle de propriété à la modification.
- **V21 — En-têtes frontend** : `vercel.json` porte désormais CSP, HSTS,
  `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy` et COOP.
- **V22 — Relais d'emails** : throttle `invitation` (10/jour/compte), validation
  de l'adresse, plafond de 8 membres, nom du groupe retiré du corps du message.
- **V23 — Pagination** : `PaginationStandard` globale (20 par page, plafond 100),
  frontend adapté via le helper `listeDepuis()`.
- **V24 — Dépendances** : **0 vulnérabilité npm** (12 auparavant, dont 1
  critique). `swiper`, `react-icons`, `date-fns`, `framer-motion`, `jwt-decode`
  et `react-image-crop` étaient **inutilisés** — supprimés, ce qui élimine la
  faille critique de prototype pollution et réduit la surface supply-chain.
  `vite` 5→7, `react-router-dom` 6→7, `axios` mis à jour.

### Moyennes et faibles

- **V25** — `str.format()` remplacé par `rendre_message()` : liste blanche de
  jetons, substitution littérale, erreurs isolées par opticien dans la tâche
  planifiée.
- **V26** — le déclenchement manuel des anniversaires est scopé à l'appelant.
- **V27** — `EnvoyerSouhaits` filtre sur les clients de l'opticien.
- **V28** — toutes les conversions `float()`/`int()` sur entrée utilisateur sont
  gardées ; `get_object_or_404` remplace les `.get()` nus.
- **V29** — gestionnaire d'exceptions DRF global : message générique + référence
  de corrélation au client, trace complète dans les logs.
- **V30** — dimensions d'image vérifiées avant décodage (anti-bombe de
  décompression) côté validateurs et essai virtuel ; throttle `ocr` (30/jour)
  sur les appels facturés à Groq.
- **V31** — messages d'inscription uniformisés sur `username`/`email`.
- **V32** — `xml.sax.saxutils.escape` sur toutes les données utilisateur
  interpolées dans les `Paragraph` ReportLab.
- **V33** — champs carte bancaire (PAN, CVV) **supprimés** du frontend.
- **V34** — sauvegarde chiffrée GPG, permissions `0600`, endpoint désactivé si
  `BACKUP_GPG_RECIPIENT` n'est pas défini.
- **V35** — Redis obligatoire en production.
- **V36** — Docker : utilisateur non-root (uid 10001), `HEALTHCHECK`, migrations
  sorties du démarrage.
- **V37** — `VisiteThrottle` basé sur l'IP et non sur `AnonRateThrottle` (qui ne
  s'appliquait pas aux utilisateurs connectés).
- **V38** — **87 tests de sécurité** ajoutés (voir plus bas).
- **V39** — admin Django durci : préfixe d'URL configurable (`ADMIN_URL`),
  limitation du débit sur son formulaire de connexion — qui échappait aux
  throttles DRF puisque c'est une vue Django classique, offrant une seconde
  porte non comptée vers les mêmes comptes —, liste blanche d'IP optionnelle
  (`ADMIN_IPS`, réponse 404 pour rester indiscernable d'une URL inexistante),
  journalisation des connexions réussies et échouées, `list_editable = ['role']`
  retiré.
- **V40** — journal d'audit (`utils/audit.py`, logger `audit`) sur les
  validations d'opticien, changements de statut, remboursements, ajustements de
  stock, consultations d'ordonnances, sauvegardes.
- **V41** — l'ordonnanceur ne démarre plus que sur `RUN_SCHEDULER=1`.
- **V43** — fichiers résiduels supprimés (`photo.jpg`, `resultat.jpg`,
  `ordonnance_test3.png`, `git_add_error.txt`, `.metadata`, capture d'écran,
  binaire `.deb`).

### Dépendances Python — découvert après coup (2026-08-25)

Le rapport initial classait ce point « à vérifier » faute de scanner installé.
`pip-audit` a depuis été installé et exécuté : **48 vulnérabilités connues**
étaient présentes.

| Paquet | Avant | Après | Vulns |
|---|---|---|---|
| `Pillow` | 12.2.0 | **12.3.0** | 20 |
| `Django` | 6.0.3 | **6.0.8** | 25 |
| `requests` | 2.32.3 | **2.34.2** | 2 |
| `python-dotenv` | 1.0.1 | **1.2.3** | 1 |

Pillow est le plus préoccupant : c'est lui qui décode **les images fournies par
les utilisateurs** (`utils/validators.py`, `montures/models.py`). Une faille de
corruption mémoire dans un décodeur d'image est directement atteignable en
uploadant une ordonnance ou une photo de monture.

Note de mise à jour : Django a d'abord été passé en 6.1, ce qui casse
`django-cors-headers` 4.9 (import `cc_delim_re` supprimé de `django.utils.cache`).
Les correctifs existant aussi sur la branche 6.0, la version retenue est
**6.0.8** — correctifs appliqués sans changement majeur.

`pip-audit -r requirements.txt` : **aucune vulnérabilité connue**.

### Bugs latents découverts en corrigeant

- `stock_management.RapportStock` filtrait sur `commandes__isnull` alors que le
  `related_name` n'existe pas → `FieldError` (500) à chaque appel. Corrigé en
  `commande`.
- `montures.ListeMontures` : un `prix_min` non numérique provoquait une 500 à
  l'évaluation du queryset.
- `essai_virtuel` chargeait le modèle MediaPipe par chemin relatif, dépendant du
  répertoire de travail du process (cassé sous gunicorn). Passé en absolu.
- `assurance.calculer_montants()` mélangeait `float` et `DecimalField` → erreurs
  d'arrondi sur des montants financiers. Passé en `Decimal`.

---

## Tests de sécurité

`backend/tests/` — 87 tests, exécutables via `python manage.py test tests`.

| Fichier | Couvre |
|---|---|
| `test_authentification.py` | rotation et révocation des jetons, refresh par cookie, escalade de privilège, énumération, bruteforce, force du mot de passe |
| `test_autorisation.py` | IDOR ordonnances, cloisonnement opticiens, contournement du filtre média, permissions assurance et publications |
| `test_logique_metier.py` | calcul de prix serveur, suppression du faux paiement, machine à états, fraude au remboursement, race conditions de stock |
| `test_entrees.py` | OTP, injection de gabarit, validation de fichiers (SVG/HTML/PHP déguisés), échappement PDF, en-têtes HTTP, protection de l'admin, garde-fous de configuration |

Chaque test cible une vulnérabilité identifiée et échouerait si la correction
était annulée.

---

## Migrations

Cinq migrations générées, à appliquer au déploiement :

```
users/0005_user_tokens_valides_apres.py
commandes/0010_alter_commande_statut.py
ordonnances/0003_alter_ordonnance_options_alter_ordonnance_image.py
sms_otp/0002_remove_otpcode_code_otpcode_code_hash_and_more.py
famille/0002_alter_groupefamille_code_invitation.py
```

`sms_otp/0002` supprime la colonne `code` en clair. Les codes en cours (durée de
vie 10 minutes) sont invalidés — sans impact au-delà de la fenêtre de bascule.

---

## Changements d'API pour le frontend

Ces ruptures sont déjà répercutées dans `frontend/`, à connaître pour tout autre
client (application mobile éventuelle) :

1. `POST /api/users/login/` ne renvoie plus `refresh` — il est dans un cookie.
2. `POST /api/users/token/refresh/` ne lit plus le corps, uniquement le cookie ;
   les appels doivent utiliser `withCredentials: true`.
3. Les listes sont paginées : `{count, next, previous, results}`.
4. `POST /api/commandes/passer/` ignore `rabais_famille`, `prix_verres` et
   `prix_total`.
5. `POST /api/commandes/<id>/paiement/confirmer/` n'existe plus (404).
6. `POST /api/assurance/demandes/` ignore `montant_total`.
7. Les ordonnances exposent `image_url` (vue authentifiée) au lieu du chemin de
   stockage.
8. `POST /api/sms/envoyer/` exige un numéro au format `+226XXXXXXXX`.

---

## Note de vérification

`python manage.py check --deploy` avec `DEBUG=False` : **0 issue**.
`npm audit` : **0 vulnérabilité**.
`tsc --noEmit` et `npm run build` : OK.

Ces vérifications portent sur le code. Elles ne disent rien de la configuration
réelle de l'hébergeur, de l'exposition du bucket R2 ni des privilèges du rôle
PostgreSQL — les trois points à confirmer manuellement.
