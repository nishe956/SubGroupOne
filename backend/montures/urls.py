from django.urls import path
from .views import MontureListView, MontureDetailView

urlpatterns = [
    path('', MontureListView.as_view(), name='monture-list'),
    path('<int:pk>/', MontureDetailView.as_view(), name='monture-detail'),
]
