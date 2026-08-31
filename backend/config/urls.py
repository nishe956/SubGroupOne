from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.views.static import serve
import posixpath

# Répertoires media contenant des données personnelles ou médicales : jamais
# servis par cette route, même en développement. Ils passent exclusivement par
# des vues authentifiées avec contrôle de propriété (ordonnances/views.py).
MEDIA_PRIVE = ('ordonnances/', 'temp_')


def cached_media(request, path):
    """Sert un média public depuis le disque local — développement uniquement.

    Le filtre ci-dessous normalise le chemin AVANT de le comparer aux préfixes
    privés. Sans cette normalisation, `django.views.static.serve` appliquait
    `posixpath.normpath` de son côté et les deux ne voyaient pas le même chemin :
    `/media//ordonnances/x.jpg`, `/media/./ordonnances/x.jpg` ou
    `/media/a/../ordonnances/x.jpg` échappaient au test `startswith` tout en
    servant bien le fichier privé.
    """
    from django.http import Http404

    chemin = posixpath.normpath('/' + (path or '')).lstrip('/')
    if not chemin or chemin == '.':
        raise Http404
    if any(chemin.startswith(prefixe) for prefixe in MEDIA_PRIVE):
        raise Http404

    response = serve(request, chemin, document_root=settings.MEDIA_ROOT)
    response['Cache-Control'] = 'public, max-age=86400'
    return response


urlpatterns = [
    # Préfixe configurable via ADMIN_URL : voir config/admin_security.py.
    path(settings.ADMIN_URL, admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/montures/', include('montures.urls')),
    path('api/ordonnances/', include('ordonnances.urls')),
    path('api/commandes/', include('commandes.urls')),
    path('api/essai/', include('essai_virtuel.urls')),
    path('api/publications/', include('publications.urls')),
    path('api/famille/', include('famille.urls')),
    path('api/marketing/', include('marketing.urls')),
    path('api/sms/', include('sms_otp.urls')),
    path('api/stock/', include('stock_management.urls')),
    path('api/maintenance/', include('maintenance.urls')),
    path('api/stats/', include('stats.urls')),
    path('api/assurance/', include('assurance.urls')),
    path('api/boutiques/', include('boutique.urls')),
]

# `django.views.static.serve` est explicitement réservé au développement par la
# documentation Django. En production les médias publics sont servis par le CDN
# (R2) et les médias privés par une vue authentifiée : la route n'est donc pas
# montée. Elle l'était inconditionnellement, alors que MEDIA_ROOT n'était défini
# que dans la branche « stockage local » — sur un déploiement S3/R2, la route
# servait donc les fichiers du répertoire de travail du process, code source
# et fichier .env compris.
if settings.DEBUG and not settings.AWS_STORAGE_BUCKET_NAME:
    urlpatterns += [re_path(r'^media/(?P<path>.*)$', cached_media)]
