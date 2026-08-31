from django.urls import path
from .views import (
    RegisterView, LoginView, LogoutView, ProfilView,
    ChangePasswordView, ListeUtilisateursView, UpdateDeleteUtilisateurView,
    CreerOpticienView, ListeOpticiens, ListeClients,
    OpticiensEnAttenteView, ValiderOpticienView,
    PasswordResetRequestView, PasswordResetConfirmView, GoogleLoginView,
    RafraichirTokenView,
)
from sms_otp.views import EnvoyerOTP, VerifierOTP

urlpatterns = [
    path('register/',         RegisterView.as_view(),                name='register'),
    path('login/',            LoginView.as_view(),                   name='login'),
    path('logout/',           LogoutView.as_view(),                  name='logout'),
    path('google-login/',     GoogleLoginView.as_view(),             name='google-login'),
    path('password-reset/',         PasswordResetRequestView.as_view(), name='password-reset'),
    path('password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
    path('profil/',           ProfilView.as_view(),                  name='profil'),
    path('change-password/',  ChangePasswordView.as_view(),          name='change-password'),
    path('send-otp/',         EnvoyerOTP.as_view(),                  name='send-otp'),
    path('verify-otp/',       VerifierOTP.as_view(),                 name='verify-otp'),
    path('liste/',            ListeUtilisateursView.as_view(),       name='liste-users'),
    path('opticiens/',            ListeOpticiens.as_view(),          name='liste-opticiens'),
    path('opticiens/en-attente/', OpticiensEnAttenteView.as_view(),  name='opticiens-en-attente'),
    path('opticiens/<int:pk>/valider/', ValiderOpticienView.as_view(), name='valider-opticien'),
    path('opticiens/creer/',      CreerOpticienView.as_view(),       name='creer-opticien'),
    path('clients/',          ListeClients.as_view(),                name='liste-clients'),
    path('<int:pk>/',         UpdateDeleteUtilisateurView.as_view(), name='update-delete-user'),
    # Le refresh token est lu dans le cookie httpOnly, jamais dans le corps.
    path('token/refresh/',    RafraichirTokenView.as_view(),         name='token-refresh'),
]
