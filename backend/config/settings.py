"""Configuration Django — source de vérité unique.

Le durcissement de production s'applique automatiquement dès que ``DEBUG`` est
faux. Il n'existe volontairement plus de module ``settings_production`` séparé :
``wsgi.py`` chargeait toujours ``config.settings``, si bien que le durcissement
prévu pour la production n'était jamais appliqué.
"""
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv
from django.core.exceptions import ImproperlyConfigured
import os

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent


def _bool(nom, defaut='False'):
    return os.getenv(nom, defaut).strip().lower() in ('true', '1', 'yes', 'on')


def _liste(nom, defaut=''):
    return [v.strip() for v in os.getenv(nom, defaut).split(',') if v.strip()]


def _int(nom, defaut):
    try:
        return int(os.getenv(nom, str(defaut)))
    except ValueError:
        return defaut


DEBUG = _bool('DEBUG')

# ─── Clé secrète ──────────────────────────────────────────────────────────────
# Les JWT sont signés en HS256 avec cette valeur : une clé devinable équivaut à
# pouvoir forger un jeton d'administrateur. Le contrôle est ici (et non dans un
# module optionnel) pour qu'il soit impossible de le contourner par oubli.
SECRET_KEY = os.getenv('SECRET_KEY')
if not SECRET_KEY:
    raise ImproperlyConfigured("La variable d'environnement SECRET_KEY est obligatoire.")

_MOTIFS_CLE_FAIBLE = ('insecure', 'change', 'remplace', 'default', 'secret-key')
if not DEBUG and (
    len(SECRET_KEY) < 50
    or any(motif in SECRET_KEY.lower() for motif in _MOTIFS_CLE_FAIBLE)
):
    raise ImproperlyConfigured(
        "SECRET_KEY non sécurisée pour la production. Générez-en une avec :\n"
        '  python -c "from django.core.management.utils import '
        'get_random_secret_key; print(get_random_secret_key())"'
    )

ALLOWED_HOSTS = _liste('ALLOWED_HOSTS', 'localhost,127.0.0.1' if DEBUG else '')
if not DEBUG and not ALLOWED_HOSTS:
    raise ImproperlyConfigured(
        "ALLOWED_HOSTS est obligatoire en production (liste de domaines séparés par des virgules)."
    )

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Bibliothèques
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'django_apscheduler',
    'storages',

    # Nos applications
    'users',
    'montures',
    'commandes',
    'ordonnances',
    'essai_virtuel',
    'publications',
    'famille',
    'marketing',
    'sms_otp',
    'stock_management',
    'maintenance',
    'stats',
    'assurance',
    'boutique',
]

# ─── Interface d'administration ───────────────────────────────────────────────
# Le préfixe par défaut `/admin/` est testé en permanence par les scanners
# automatisés. Le changer ne remplace pas une vraie protection, mais supprime le
# bruit de fond et les tentatives opportunistes.
ADMIN_URL = os.getenv('ADMIN_URL', 'admin/').strip('/') + '/'
# Liste blanche d'adresses IP autorisées à joindre l'admin. Vide = pas de
# restriction réseau (indispensable en développement).
ADMIN_IPS = _liste('ADMIN_IPS')

MIDDLEWARE = [
    # En tête : la sonde de vivacité doit répondre même quand ALLOWED_HOSTS, la
    # redirection HTTPS ou la limitation de débit rejetteraient la requête.
    'config.middleware.HealthCheckMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'config.middleware.SecurityHeadersMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    # Après SessionMiddleware (besoin de la session) et avant les vues : filtre
    # réseau et limitation du débit sur la connexion à l'admin.
    'config.admin_security.ProtectionAdminMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': os.getenv('DB_PORT'),
        # 'require' par défaut en production : la base est hébergée à distance
        # (Neon), le trafic ne doit jamais transiter en clair.
        'OPTIONS': {'sslmode': os.getenv('DB_SSLMODE', 'prefer' if DEBUG else 'require')},
        'CONN_MAX_AGE': _int('DB_CONN_MAX_AGE', 60),
    }
}

# ─── API REST ─────────────────────────────────────────────────────────────────
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        # Variante qui refuse les jetons émis avant une révocation explicite
        # (changement de mot de passe, rejet ou désactivation de compte).
        'users.authentication.JWTAuthentificationRevocable',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    # Sans pagination, chaque liste renvoyait l'intégralité de la table :
    # extraction de masse triviale et consommation mémoire proportionnelle à la base.
    'DEFAULT_PAGINATION_CLASS': 'utils.pagination.PaginationStandard',
    'PAGE_SIZE': 20,
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.UserRateThrottle',
        'rest_framework.throttling.AnonRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'user': '1000/day',
        'anon': '100/day',
        # Quotas dédiés aux endpoints sensibles ou coûteux.
        'connexion': '10/hour',      # tentatives de connexion, par IP
        'inscription': '10/hour',    # créations de compte, par IP
        'reset': '5/hour',           # demandes de réinitialisation, par IP
        'otp': '10/hour',            # envois de SMS, par IP
        'ocr': '30/day',             # appels facturés à l'API Groq, par utilisateur
        'invitation': '10/day',      # emails d'invitation famille, par utilisateur
        'essai': '60/hour',          # essai virtuel (décodage d'image coûteux)
        # Enregistrement des pages vues : un visiteur légitime en génère beaucoup
        # plus qu'un appel API classique, d'où un quota dédié.
        'visites': '120/hour',
    },
    # Nombre de proxys de confiance devant l'application. À 0 (défaut), DRF
    # utilise REMOTE_ADDR ; sinon il ferait confiance à X-Forwarded-For, en-tête
    # que n'importe quel client peut falsifier pour annuler toutes les limites.
    'NUM_PROXIES': _int('NUM_PROXIES', 0),
    'EXCEPTION_HANDLER': 'utils.exceptions.gestionnaire_exceptions',
}

# ─── Jetons JWT ───────────────────────────────────────────────────────────────
# Rotation et blacklist actives dans TOUS les environnements : un refresh token
# volé ne doit jamais rester utilisable jusqu'à son expiration naturelle.
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=_int('JWT_ACCESS_MINUTES', 15)),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=_int('JWT_REFRESH_DAYS', 7 if DEBUG else 1)),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
     'OPTIONS': {'min_length': 10}},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Les liens de réinitialisation annoncent 24 h dans l'email : la durée réelle
# doit correspondre (le défaut Django est de 3 jours).
PASSWORD_RESET_TIMEOUT = 60 * 60 * 24

# ─── CORS / CSRF ──────────────────────────────────────────────────────────────
CORS_ALLOW_ALL_ORIGINS = False
# Nécessaire pour que le navigateur transmette le cookie httpOnly du refresh token
# au domaine de l'API. La liste d'origines ci-dessous reste strictement blanche.
CORS_ALLOW_CREDENTIALS = True

if DEBUG:
    CORS_ALLOWED_ORIGINS = [
        'http://localhost:5173',
        'http://127.0.0.1:5173',
        'https://localhost:5173',
        'https://127.0.0.1:5173',
        'http://localhost:3000',
    ]
    CSRF_TRUSTED_ORIGINS = list(CORS_ALLOWED_ORIGINS)
else:
    CORS_ALLOWED_ORIGINS = _liste('CORS_ALLOWED_ORIGINS')
    if not CORS_ALLOWED_ORIGINS:
        raise ImproperlyConfigured(
            "CORS_ALLOWED_ORIGINS est obligatoire en production (URL du frontend)."
        )
    CSRF_TRUSTED_ORIGINS = _liste('CSRF_TRUSTED_ORIGINS') or list(CORS_ALLOWED_ORIGINS)

# ─── Durcissement HTTPS et cookies ────────────────────────────────────────────
# TRUST_PROXY doit être activé lorsqu'un reverse proxy termine le TLS (Render,
# nginx, dev_https_proxy.py). Sans cela, Django ne verrait que du HTTP et la
# redirection SSL boucherait indéfiniment.
TRUST_PROXY = _bool('TRUST_PROXY', 'True' if DEBUG else 'False')
if TRUST_PROXY:
    USE_X_FORWARDED_HOST = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'
CSRF_COOKIE_SAMESITE = 'Lax'

if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'
    X_FRAME_OPTIONS = 'DENY'

# Cookie portant le refresh token. En production, le frontend (Vercel) et l'API
# (Render) sont sur des sites différents : le cookie doit être SameSite=None pour
# être transmis, ce qui impose Secure.
REFRESH_COOKIE_NAME = 'refresh_token'
REFRESH_COOKIE_PATH = '/api/users/token/refresh/'
REFRESH_COOKIE_SECURE = not DEBUG
REFRESH_COOKIE_SAMESITE = 'Lax' if DEBUG else 'None'

# ─── Limites d'upload ─────────────────────────────────────────────────────────
# Plafond du corps de requête. Doit rester au-dessus de la taille de fichier
# acceptée par utils.validators, sinon Django rejette l'upload avant validation.
DATA_UPLOAD_MAX_MEMORY_SIZE = _int('DATA_UPLOAD_MAX_MEMORY_SIZE', 25 * 1024 * 1024)
FILE_UPLOAD_MAX_MEMORY_SIZE = 5 * 1024 * 1024
DATA_UPLOAD_MAX_NUMBER_FIELDS = 200
# Nombre de pixels au-delà duquel Pillow refuse de décoder une image
# (protection contre les « decompression bombs »).
IMAGE_MAX_PIXELS = _int('IMAGE_MAX_PIXELS', 50_000_000)

# ─── URLs et intégrations ─────────────────────────────────────────────────────
FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:5173')
GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID', '')
DEFAULT_FROM_EMAIL = os.getenv('EMAIL_FROM', 'noreply@optilunette.bf')

if os.getenv('EMAIL_HOST'):
    EMAIL_BACKEND  = 'django.core.mail.backends.smtp.EmailBackend'
    EMAIL_HOST     = os.getenv('EMAIL_HOST')
    EMAIL_PORT     = _int('EMAIL_PORT', 587)
    # TLS (port 587) et SSL (port 465) sont mutuellement exclusifs.
    EMAIL_USE_SSL  = _bool('EMAIL_USE_SSL')
    EMAIL_USE_TLS  = (not EMAIL_USE_SSL) and _bool('EMAIL_USE_TLS', 'True')
    EMAIL_HOST_USER     = os.getenv('EMAIL_HOST_USER', '')
    EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD', '')
    EMAIL_TIMEOUT       = 15
else:
    # Fallback : affiche les emails dans la console (développement)
    EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# ─── Cache ────────────────────────────────────────────────────────────────────
# LocMemCache est local à chaque process : avec plusieurs workers gunicorn, les
# compteurs anti-bruteforce sont dupliqués et le mode maintenance devient
# incohérent. Un cache partagé est donc obligatoire en production.
REDIS_URL = os.getenv('REDIS_URL', '')
if REDIS_URL:
    CACHES = {
        'default': {
            'BACKEND': 'django.core.cache.backends.redis.RedisCache',
            'LOCATION': REDIS_URL,
        }
    }
elif DEBUG:
    CACHES = {
        'default': {'BACKEND': 'django.core.cache.backends.locmem.LocMemCache'}
    }
else:
    raise ImproperlyConfigured(
        "REDIS_URL est obligatoire en production : les limites de débit et le mode "
        "maintenance reposent sur un cache partagé entre les workers."
    )

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'Africa/Ouagadougou'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# ─── Stockage des médias ──────────────────────────────────────────────────────
# Deux catégories, séparées volontairement :
#  - médias publics (photos de montures, logos, illustrations) → bucket public/CDN ;
#  - médias privés (ordonnances = données de santé) → jamais servis directement,
#    uniquement via ordonnances.views.TelechargerOrdonnance après contrôle d'accès.
#
# MEDIA_ROOT est défini dans TOUS les cas : laissé indéfini, il retombait sur la
# chaîne vide et django.views.static.serve résolvait alors les chemins depuis le
# répertoire de travail du process, exposant l'intégralité du code source.
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

AWS_STORAGE_BUCKET_NAME = os.getenv('AWS_STORAGE_BUCKET_NAME', '')
# Bucket privé dédié aux documents médicaux. S'il n'est pas renseigné, les
# ordonnances restent sur le disque local, hors de toute route publique.
AWS_PRIVATE_BUCKET_NAME = os.getenv('AWS_PRIVATE_BUCKET_NAME', '')

_STOCKAGE_STATIQUE = {'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage'}

if AWS_STORAGE_BUCKET_NAME:
    AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
    AWS_S3_ENDPOINT_URL = os.getenv('AWS_S3_ENDPOINT_URL')
    AWS_S3_CUSTOM_DOMAIN = os.getenv('AWS_S3_CUSTOM_DOMAIN', '')
    AWS_DEFAULT_ACL = None
    AWS_S3_ADDRESSING_STYLE = 'virtual'

    STORAGES = {
        # Stockage par défaut = médias publics, servis par le CDN.
        'default': {
            'BACKEND': 'storages.backends.s3.S3Storage',
            'OPTIONS': {
                'bucket_name': AWS_STORAGE_BUCKET_NAME,
                'access_key': AWS_ACCESS_KEY_ID,
                'secret_key': AWS_SECRET_ACCESS_KEY,
                'endpoint_url': AWS_S3_ENDPOINT_URL,
                'custom_domain': AWS_S3_CUSTOM_DOMAIN or None,
                'default_acl': None,
                'querystring_auth': False,
            },
        },
        'staticfiles': _STOCKAGE_STATIQUE,
    }

    if AWS_PRIVATE_BUCKET_NAME:
        # Bucket séparé, sans domaine public : chaque accès passe par une URL
        # signée de courte durée générée côté serveur après contrôle d'accès.
        STORAGES['prive'] = {
            'BACKEND': 'storages.backends.s3.S3Storage',
            'OPTIONS': {
                'bucket_name': AWS_PRIVATE_BUCKET_NAME,
                'access_key': AWS_ACCESS_KEY_ID,
                'secret_key': AWS_SECRET_ACCESS_KEY,
                'endpoint_url': AWS_S3_ENDPOINT_URL,
                'default_acl': 'private',
                'querystring_auth': True,
                'querystring_expire': 300,
                'custom_domain': None,
            },
        }
    elif not DEBUG:
        raise ImproperlyConfigured(
            "AWS_PRIVATE_BUCKET_NAME est obligatoire dès qu'un bucket public est "
            "configuré : les ordonnances sont des données de santé et ne doivent "
            "jamais être déposées dans le bucket public du catalogue."
        )

    if AWS_S3_CUSTOM_DOMAIN:
        MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/'
else:
    STORAGES = {
        'default': {'BACKEND': 'django.core.files.storage.FileSystemStorage'},
        'staticfiles': _STOCKAGE_STATIQUE,
    }

# Alias utilisé par les modèles portant des documents confidentiels.
STOCKAGE_PRIVE = 'prive' if 'prive' in STORAGES else 'default'

# ─── Journalisation ───────────────────────────────────────────────────────────
_LOG_PATH = os.getenv('DJANGO_LOG_PATH', '')
_handlers = {
    'console': {
        'level': 'DEBUG' if DEBUG else 'INFO',
        'class': 'logging.StreamHandler',
        'formatter': 'standard',
    },
}
if _LOG_PATH:
    Path(_LOG_PATH).parent.mkdir(parents=True, exist_ok=True)
    _handlers['file'] = {
        'level': 'INFO',
        'class': 'logging.handlers.RotatingFileHandler',
        'filename': _LOG_PATH,
        'maxBytes': 10 * 1024 * 1024,
        'backupCount': 5,
        'formatter': 'standard',
    }

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'standard': {'format': '%(asctime)s %(levelname)s %(name)s %(message)s'},
    },
    'handlers': _handlers,
    'root': {'handlers': list(_handlers), 'level': 'DEBUG' if DEBUG else 'INFO'},
    'loggers': {
        # Journal d'audit des actions sensibles (validations, remboursements,
        # changements de statut, sauvegardes).
        'audit': {'handlers': list(_handlers), 'level': 'INFO', 'propagate': False},
        # Bibliothèques tierces très bavardes en DEBUG : leur bruit masquerait
        # les événements de sécurité dans le journal.
        'matplotlib': {'level': 'WARNING'},
        'PIL': {'level': 'WARNING'},
        'botocore': {'level': 'WARNING'},
        'boto3': {'level': 'WARNING'},
        's3transfer': {'level': 'WARNING'},
        'urllib3': {'level': 'WARNING'},
        'apscheduler': {'level': 'WARNING'},
        'django.db.backends': {'level': 'WARNING'},
    },
}

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

AUTH_USER_MODEL = 'users.User'
