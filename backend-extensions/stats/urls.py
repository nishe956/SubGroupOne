from django.urls import path
from . import views

urlpatterns = [
    path('dashboard/', views.DashboardStats.as_view(), name='stats-dashboard'),
]
