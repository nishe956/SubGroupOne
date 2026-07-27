from django.urls import path
from . import views

urlpatterns = [
    path('',           views.MonGroupe.as_view(),     name='mon-groupe'),
    path('creer/',     views.CreerGroupe.as_view(),   name='creer-groupe'),
    path('inviter/',   views.InviterMembre.as_view(), name='inviter-membre'),
    path('rejoindre/', views.RejoindreGroupe.as_view(), name='rejoindre-groupe'),
    path('quitter/',   views.QuitterGroupe.as_view(), name='quitter-groupe'),
    path('membres/',   views.MembresFamille.as_view(), name='membres-famille'),
    path('rabais/',    views.RabaisFamille.as_view(),  name='rabais-famille'),
]
