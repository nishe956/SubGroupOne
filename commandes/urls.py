from django.urls import path
from .views import (
    PasserCommande, ListeCommandes, DetailCommande,
    GererCommande, AnnulerCommande, InitierPaiement, ConfirmerPaiement,
)

urlpatterns = [
    path('',                          ListeCommandes.as_view(),    name='liste-commandes'),
    path('passer/',                   PasserCommande.as_view(),    name='passer-commande'),
    path('<int:pk>/',                 DetailCommande.as_view(),    name='detail-commande'),
    path('<int:pk>/gerer/',           GererCommande.as_view(),     name='gerer-commande'),
    path('<int:pk>/annuler/',         AnnulerCommande.as_view(),   name='annuler-commande'),
    path('<int:pk>/paiement/',        InitierPaiement.as_view(),   name='initier-paiement'),
    path('<int:pk>/paiement/confirmer/', ConfirmerPaiement.as_view(), name='confirmer-paiement'),
]
