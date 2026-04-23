from django.urls import path
from . import views

urlpatterns = [
    path('compagnies/',          views.ListeCompagnies.as_view(),         name='liste-compagnies'),
    path('compagnies/<int:pk>/', views.DetailCompagnie.as_view(),         name='detail-compagnie'),
    path('simuler/',             views.SimulerRemboursement.as_view(),    name='simuler-remboursement'),
    path('demandes/',            views.MesDemandesRemboursement.as_view(), name='mes-demandes'),
    path('demandes/<int:pk>/traiter/', views.TraiterDemande.as_view(),    name='traiter-demande'),
]
