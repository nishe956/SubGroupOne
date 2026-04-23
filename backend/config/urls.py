from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve
from django.http import FileResponse
import os


def cached_media(request, path):
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
