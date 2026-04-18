from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CommandeListCreateView, CommandeDetailView, OpticianCommandeViewSet

router = DefaultRouter()
router.register('all', OpticianCommandeViewSet, basename='optician-commandes')

urlpatterns = [
    path('', CommandeListCreateView.as_view(), name='commande-list'),
    path('<int:pk>/', CommandeDetailView.as_view(), name='commande-detail'),
    path('', include(router.urls)),
]
