# Guide d'intégration — Extensions Backend Django

## 1. Copier les modules dans votre projet Django

```bash
cp -r publications/  /path/to/your/django/project/
cp -r famille/       /path/to/your/django/project/
cp -r marketing/     /path/to/your/django/project/
cp -r sms_otp/       /path/to/your/django/project/
cp -r stock_management/ /path/to/your/django/project/
cp -r maintenance/   /path/to/your/django/project/
cp -r stats/         /path/to/your/django/project/
```

## 2. Ajouter à INSTALLED_APPS dans settings.py

```python
INSTALLED_APPS = [
    # ... apps existantes ...
    'publications',
    'famille',
    'marketing',
    'sms_otp',
    'stock_management',
    'maintenance',
    'stats',
]
```

## 3. Ajouter à config/urls.py

```python
urlpatterns = [
    # ... urls existantes ...
    path('api/publications/', include('publications.urls')),
    path('api/famille/',      include('famille.urls')),
    path('api/marketing/',    include('marketing.urls')),
    path('api/users/send-otp/',    include('sms_otp.urls')),  # send-otp/ et verify-otp/
    path('api/stock/',        include('stock_management.urls')),
    path('api/maintenance/',  include('maintenance.urls')),
    path('api/stats/',        include('stats.urls')),
]
```

**Note**: Pour les OTP, les endpoints doivent être:
- `POST /api/users/send-otp/`  → `sms_otp.views.EnvoyerOTP`
- `POST /api/users/verify-otp/` → `sms_otp.views.VerifierOTP`

## 4. Mettre à jour le modèle User (users/models.py)

```python
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLES = [('client', 'Client'), ('opticien', 'Opticien'), ('admin', 'Administrateur')]
    role          = models.CharField(max_length=20, choices=ROLES, default='client')
    telephone     = models.CharField(max_length=20, blank=True, null=True)
    adresse       = models.TextField(blank=True, null=True)
    date_naissance = models.DateField(blank=True, null=True)  # ← AJOUTER
```

## 5. Créer les migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

## 6. Variables d'environnement (.env)

```env
# Base
SECRET_KEY=your-secret-key
DEBUG=True
DJANGO_ENV=development

# Database
DB_NAME=lunette_db
DB_USER=postgres
DB_PASSWORD=your-password
DB_HOST=localhost
DB_PORT=5432

# SMS (choisir un fournisseur)
SMS_PROVIDER=mock   # mock | orange | twilio | africastalking

# Orange SMS API
ORANGE_TOKEN_URL=https://api.orange.com/oauth/v2/token
ORANGE_CLIENT_ID=your-client-id
ORANGE_CLIENT_SECRET=your-secret
ORANGE_SMS_URL=https://api.orange.com/smsmessaging/v1/...
ORANGE_SENDER=OptiLunette

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your@email.com
EMAIL_HOST_PASSWORD=your-password
DEFAULT_FROM_EMAIL=OptiLunette <noreply@optilunette.bf>

# Backups
BACKUP_DIR=backups/
DJANGO_LOG_PATH=logs/django.log
```

## 7. Recommandation montures (API)

Ajouter dans `montures/views.py`:

```python
class RecommenderMontures(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        sphere_od = request.data.get('sphere_od')
        sphere_og = request.data.get('sphere_og')
        
        # Logique de recommandation basée sur la prescription
        montures = Monture.objects.filter(disponible=True, stock__gt=0)
        
        # Recommander verres correcteurs selon la sphère
        if sphere_od or sphere_og:
            # Toutes les montures compatibles avec correction
            montures = montures.filter(description__icontains='correcteur')[:6]
        
        from .serializers import MontureSerializer
        return Response(MontureSerializer(montures, many=True).data)
```

Ajouter dans `montures/urls.py`:
```python
path('recommander/', views.RecommenderMontures.as_view(), name='recommander-montures'),
```

## 8. Middleware de maintenance

Créer `maintenance/middleware.py`:

```python
from django.core.cache import cache
from django.http import JsonResponse
import json

class MaintenanceMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Skip for admin and maintenance API itself
        if request.path.startswith('/admin') or request.path.startswith('/api/maintenance/'):
            return self.get_response(request)
        
        if cache.get('site_maintenance', False):
            message = cache.get('site_maintenance_message', 'Site en maintenance.')
            return JsonResponse({'detail': message, 'maintenance': True}, status=503)
        
        return self.get_response(request)
```

Ajouter dans settings.py:
```python
MIDDLEWARE = [
    # ... middlewares existants ...
    'maintenance.middleware.MaintenanceMiddleware',
]
```
