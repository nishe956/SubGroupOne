from django.urls import path
from . import views

urlpatterns = [
    path('statut/',     views.StatutMaintenance.as_view(),   name='maintenance-statut'),
    path('activer/',    views.ActiverMaintenance.as_view(),  name='maintenance-activer'),
    path('desactiver/', views.DesactiverMaintenance.as_view(), name='maintenance-desactiver'),
    path('logs/',       views.LogsSysteme.as_view(),         name='maintenance-logs'),
    path('backup/',     views.SauvegardeDB.as_view(),        name='maintenance-backup'),
]
