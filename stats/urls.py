from django.urls import path
from . import views

urlpatterns = [
    path('dashboard/', views.DashboardStats.as_view(), name='stats-dashboard'),
    path('ventes/',    views.VentesStats.as_view(),    name='stats-ventes'),
    path('clients/',   views.ClientsStats.as_view(),   name='stats-clients'),
    path('montures/',  views.MonturesStats.as_view(),  name='stats-montures'),
    path('revenus/',   views.RevenusStats.as_view(),   name='stats-revenus'),
]
