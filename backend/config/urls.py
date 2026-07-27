from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve
from django.http import FileResponse, Http404
import os

# Répertoires media contenant des données personnelles/médicales : jamais servis en public.
# Ils passent par des vues authentifiées avec contrôle de propriété (ex. ordonnances/views.py).
MEDIA_PRIVE = ('ordonnances/', 'temp_')


def cached_media(request, path):
    if any(path.startswith(prefixe) for prefixe in MEDIA_PRIVE):
        raise Http404
    response = serve(request, path, document_root=settings.MEDIA_ROOT)
    response['Cache-Control'] = 'public, max-age=86400'
    return response


urlpatterns = [
    path('admin/', admin.site.urls),
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
    re_path(r'^media/(?P<path>.*)$', cached_media),
]
