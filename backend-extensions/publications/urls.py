from django.urls import path
from . import views

urlpatterns = [
    path('',              views.ListePublications.as_view(),    name='liste-publications'),
    path('creer/',        views.CreerPublication.as_view(),     name='creer-publication'),
    path('<int:pk>/',     views.DetailPublication.as_view(),    name='detail-publication'),
    path('<int:pk>/liker/', views.LikerPublication.as_view(),   name='liker-publication'),
    path('<int:pk>/commenter/', views.CommenterPublication.as_view(), name='commenter-publication'),
]
