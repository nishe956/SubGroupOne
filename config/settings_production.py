"""
Settings à appliquer en production.
Usage : DJANGO_SETTINGS_MODULE=config.settings_production
"""
from .settings import *

DEBUG = False

SECRET_KEY = os.getenv('SECRET_KEY')
if not SECRET_KEY or 'insecure' in SECRET_KEY or 'change' in SECRET_KEY.lower():
    raise RuntimeError("SECRET_KEY non définie ou non sécurisée. Définissez une vraie clé dans .env")

ALLOWED_HOSTS = [h.strip() for h in os.getenv('ALLOWED_HOSTS', '').split(',') if h.strip()]

# CORS : uniquement le frontend autorisé
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = [
    'https://optilunette.bf',
    'https://www.optilunette.bf',
]

# En-têtes de sécurité HTTPS
SECURE_HSTS_SECONDS = 31536000          # 1 an
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# Tokens JWT plus courts en production
from datetime import timedelta
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=30),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
}

# Logs
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'WARNING',
            'class': 'logging.FileHandler',
            'filename': os.getenv('DJANGO_LOG_PATH', 'logs/django.log'),
        },
    },
    'root': {
        'handlers': ['file'],
        'level': 'WARNING',
    },
}
