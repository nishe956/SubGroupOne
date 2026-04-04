from django.urls import path
from .views import EssayerMontureView

urlpatterns = [
    path('essayer/', EssayerMontureView.as_view(), name='essayer-monture'),
]