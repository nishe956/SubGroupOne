from django.urls import path
from . import views

urlpatterns = [
    path('anniversaires/',              views.ClientsAnniversaire.as_view(),          name='clients-anniversaire'),
    path('souhaits/<int:pk>/',          views.EnvoyerSouhaits.as_view(),              name='envoyer-souhaits'),
    path('sms/envoyer/',               views.EnvoyerSMSCollectif.as_view(),           name='sms-collectif'),
    path('sms/historique/',            views.HistoriqueSMSView.as_view(),             name='sms-historique'),
    path('campagnes/',                 views.CampagnesView.as_view(),                 name='campagnes'),
    path('stats/',                     views.StatsMarketing.as_view(),                name='stats-marketing'),
    path('segments/',                  views.SegmentsClients.as_view(),               name='segments-clients'),
    path('auto-anniversaire/',         views.ConfigAutoAnniversaireView.as_view(),    name='config-auto-anniversaire'),
    path('auto-anniversaire/lancer/',  views.DeclenchemanualAnniversaires.as_view(),  name='lancer-anniversaires'),
]
