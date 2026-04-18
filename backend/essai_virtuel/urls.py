from django.urls import path
from .views import EssaiVirtuelListView, CreerEssaiView

urlpatterns = [
    path('', EssaiVirtuelListView.as_view(), name='essai-list'),
    path('creer/', CreerEssaiView.as_view(), name='creer-essai'),
]
