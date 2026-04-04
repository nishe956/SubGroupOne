from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/montures/', include('montures.urls')),
    path('api/ordonnances/', include('ordonnances.urls')),
    path('api/commandes/', include('commandes.urls')),
    path('api/essai/', include('essai_virtuel.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)