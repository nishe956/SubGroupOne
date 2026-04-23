from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, LoginView, LogoutView, ProfilView,
    ChangePasswordView, ListeUtilisateursView, UpdateDeleteUtilisateurView,
    CreerOpticienView, ListeOpticiens, ListeClients,
)
from sms_otp.views import EnvoyerOTP, VerifierOTP

urlpatterns = [
    path('register/',         RegisterView.as_view(),                name='register'),
    path('login/',            LoginView.as_view(),                   name='login'),
    path('logout/',           LogoutView.as_view(),                  name='logout'),
    path('profil/',           ProfilView.as_view(),                  name='profil'),
    path('change-password/',  ChangePasswordView.as_view(),          name='change-password'),
    path('send-otp/',         EnvoyerOTP.as_view(),                  name='send-otp'),
    path('verify-otp/',       VerifierOTP.as_view(),                 name='verify-otp'),
    path('liste/',            ListeUtilisateursView.as_view(),       name='liste-users'),
    path('opticiens/',        ListeOpticiens.as_view(),              name='liste-opticiens'),
    path('opticiens/creer/',  CreerOpticienView.as_view(),           name='creer-opticien'),
    path('clients/',          ListeClients.as_view(),                name='liste-clients'),
    path('<int:pk>/',         UpdateDeleteUtilisateurView.as_view(), name='update-delete-user'),
    path('token/refresh/',    TokenRefreshView.as_view(),            name='token-refresh'),
]
