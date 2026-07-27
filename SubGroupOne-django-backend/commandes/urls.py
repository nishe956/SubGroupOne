from django.urls import path
from .views import (
    PasserCommande,
    ListeCommandes,
    DetailCommande,
    GererCommande
)

urlpatterns = [
    path('', ListeCommandes.as_view(), name='liste-commandes'),
    path('passer/', PasserCommande.as_view(), name='passer-commande'),
    path('<int:pk>/', DetailCommande.as_view(), name='detail-commande'),
    path('<int:pk>/gerer/', GererCommande.as_view(), name='gerer-commande'),
]