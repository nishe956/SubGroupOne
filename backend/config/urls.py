import os
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]

# Helper to safely include URLs if they exist
def safe_include(app_name):
    app_urls_path = os.path.join(settings.BASE_DIR, app_name, 'urls.py')
    if os.path.exists(app_urls_path):
        return [path(f'api/{app_name.replace("_", "-")}/', include(f'{app_name}.urls'))]
    return []

urlpatterns += safe_include('users')
urlpatterns += safe_include('montures')
urlpatterns += safe_include('ordonnances')
urlpatterns += safe_include('commandes')
urlpatterns += safe_include('essai_virtuel')

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
