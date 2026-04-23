from django.db import models
from django.conf import settings
import random, string


def generer_code():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))


class GroupeFamille(models.Model):
    nom           = models.CharField(max_length=100)
    chef          = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='groupes_crees')
    membres       = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='groupes_famille', blank=True)
    code_invitation = models.CharField(max_length=6, unique=True, default=generer_code)
    date_creation = models.DateTimeField(auto_now_add=True)
    actif         = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Groupe Famille'

    def __str__(self):
        return f"{self.nom} ({self.membres.count()} membres)"

    def taux_rabais(self):
        n = self.membres.count()
        if n >= 4: return 0.15
        if n >= 3: return 0.10
        if n >= 2: return 0.05
        return 0.0

    def nb_membres(self):
        return self.membres.count()
