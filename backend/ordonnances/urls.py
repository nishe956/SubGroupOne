from django.urls import path
from .views import OrdonnanceListView, ScannerOrdonnanceView, AdminOrdonnanceListView

urlpatterns = [
    path('', OrdonnanceListView.as_view(), name='ordonnance-list'),
    path('scanner/', ScannerOrdonnanceView.as_view(), name='scanner-ordonnance'),
    path('all/', AdminOrdonnanceListView.as_view(), name='admin-ordonnances'),
]
