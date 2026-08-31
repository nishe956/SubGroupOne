from django.db import models
from django.conf import settings
import secrets, string

# 'I', 'O', '0' et '1' sont exclus : ils se confondent à la lecture d'un code
# communiqué de vive voix ou par SMS.
_ALPHABET_CODE = ''.join(c for c in string.ascii_uppercase + string.digits if c not in 'IO01')


def generer_code():
    """Code d'invitation imprévisible.

    `random.choices` s'appuie sur un générateur non cryptographique : la suite
    des codes émis serait reconstructible à partir d'observations suffisantes.
    """
    return ''.join(secrets.choice(_ALPHABET_CODE) for _ in range(8))


class GroupeFamille(models.Model):
    nom           = models.CharField(max_length=100)
    chef          = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='groupes_crees')
    membres       = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='groupes_famille', blank=True)
    code_invitation = models.CharField(max_length=8, unique=True, default=generer_code)
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
