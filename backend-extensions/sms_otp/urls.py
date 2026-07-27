from django.urls import path
from . import views

urlpatterns = [
    path('envoyer/',  views.EnvoyerOTP.as_view(),  name='envoyer-otp'),
    path('verifier/', views.VerifierOTP.as_view(), name='verifier-otp'),
]
