from django.urls import path
from .views import (
    AjouterOrdonnance,
    ScannerOrdonnance,
    ListeOrdonnances,
    DetailOrdonnance,
    ValiderOrdonnance,
    TelechargerOrdonnance,
)

urlpatterns = [
    path('', ListeOrdonnances.as_view(), name='liste-ordonnances'),
    path('ajouter/', AjouterOrdonnance.as_view(), name='ajouter-ordonnance'),
    path('scanner/', ScannerOrdonnance.as_view(), name='scanner-ordonnance'),
    path('<int:pk>/', DetailOrdonnance.as_view(), name='detail-ordonnance'),
    path('<int:pk>/valider/', ValiderOrdonnance.as_view(), name='valider-ordonnance'),
    path('<int:pk>/image/', TelechargerOrdonnance.as_view(), name='image-ordonnance'),
]