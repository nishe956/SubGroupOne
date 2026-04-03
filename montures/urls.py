from django.urls import path
from .views import ListeMontures, DetailMonture

urlpatterns = [
    path('', ListeMontures.as_view(), name='liste-montures'),
    path('<int:pk>/', DetailMonture.as_view(), name='detail-monture'),
]