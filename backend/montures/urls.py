from django.urls import path
from .views import (
    ListeMontures, DetailMonture, UpdateStockMonture, RecommenderMontures,
    AjouterImage, SupprimerImage, SupprimerImagePrincipale,
)

urlpatterns = [
    path('',                           ListeMontures.as_view(),           name='liste-montures'),
    path('recommander/',               RecommenderMontures.as_view(),     name='recommander-montures'),
    path('<int:pk>/',                  DetailMonture.as_view(),           name='detail-monture'),
    path('<int:pk>/stock/',            UpdateStockMonture.as_view(),      name='update-stock-monture'),
    path('<int:pk>/images/',           AjouterImage.as_view(),            name='ajouter-image'),
    path('<int:pk>/images/principale/', SupprimerImagePrincipale.as_view(), name='suppr-image-principale'),
    path('<int:pk>/images/<int:image_id>/', SupprimerImage.as_view(),    name='supprimer-image'),
]
