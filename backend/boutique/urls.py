from django.urls import path
from .views import MaBoutique, ListeBoutiques, DetailBoutique

urlpatterns = [
    path('ma-boutique/', MaBoutique.as_view(), name='ma-boutique'),
    path('', ListeBoutiques.as_view(), name='liste-boutiques'),
    path('<int:pk>/', DetailBoutique.as_view(), name='detail-boutique'),
]
