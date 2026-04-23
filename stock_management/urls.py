from django.urls import path
from . import views

urlpatterns = [
    path('overview/',    views.StockOverview.as_view(),    name='stock-overview'),
    path('alertes/',     views.AlertesStock.as_view(),     name='stock-alertes'),
    path('ajuster/',     views.AjustementStock.as_view(),  name='stock-ajuster'),
    path('rapport/',     views.RapportStock.as_view(),     name='stock-rapport'),
    path('mouvements/',  views.MouvementsStock.as_view(),  name='stock-mouvements'),
]
