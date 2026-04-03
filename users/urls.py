from django.urls import path
from .views import RegisterView, LoginView, ProfilView, ListeUtilisateursView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('profil/', ProfilView.as_view(), name='profil'),
    path('liste/', ListeUtilisateursView.as_view(), name='liste-users'),
]