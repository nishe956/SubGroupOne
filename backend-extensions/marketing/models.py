from django.db import models
from django.conf import settings


class HistoriqueSMS(models.Model):
    destinataire    = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='sms_recus')
    telephone       = models.CharField(max_length=20)
    message         = models.TextField()
    type_message    = models.CharField(max_length=50, default='promo')  # anniversaire, promo, relance
    envoye          = models.BooleanField(default=False)
    date_envoi      = models.DateTimeField(auto_now_add=True)
    envoye_par      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='sms_envoyes')

    class Meta:
        ordering = ['-date_envoi']
        verbose_name = 'Historique SMS'

    def __str__(self):
        return f"SMS à {self.telephone} [{self.type_message}]"


class CampagneMarketing(models.Model):
    STATUTS = [('brouillon', 'Brouillon'), ('active', 'Active'), ('terminee', 'Terminée')]

    nom         = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    message     = models.TextField()
    statut      = models.CharField(max_length=20, choices=STATUTS, default='brouillon')
    cible       = models.CharField(max_length=50, default='all')  # all, anniversaire, inactifs
    date_debut  = models.DateField(null=True, blank=True)
    date_fin    = models.DateField(null=True, blank=True)
    nb_envoyes  = models.PositiveIntegerField(default=0)
    creee_par   = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_creation']

    def __str__(self):
        return self.nom
