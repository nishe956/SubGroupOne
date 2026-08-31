import hashlib
import hmac
import secrets
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone

TENTATIVES_MAX = 3
DUREE_VALIDITE = timedelta(minutes=10)


def generer_code():
    """Code à 6 chiffres tiré d'un générateur cryptographique.

    `random.randint` s'appuie sur un Mersenne Twister : la suite produite est
    reconstructible à partir d'un nombre suffisant d'observations, ce qui rend
    les codes suivants prédictibles.
    """
    return f"{secrets.randbelow(1_000_000):06d}"


# Ancien nom, référencé par la migration 0001_initial : conservé pour que
# l'historique des migrations reste chargeable.
generer_otp = generer_code


def hacher_code(code):
    """Empreinte HMAC du code, avec la clé du projet comme sel.

    Le code n'est jamais stocké en clair : un accès en lecture à la base ne doit
    pas suffire à valider une vérification téléphonique.
    """
    return hmac.new(
        settings.SECRET_KEY.encode(), code.encode(), hashlib.sha256
    ).hexdigest()


class OTPCode(models.Model):
    TYPES = [
        ('registration', 'Inscription'),
        ('login',        'Connexion'),
        ('reset',        'Réinitialisation'),
    ]

    telephone   = models.CharField(max_length=20, db_index=True)
    # `default=''` : les codes existants (durée de vie 10 minutes) ne sont pas
    # migrables puisqu'ils n'étaient pas hachés ; une empreinte vide ne
    # correspond à aucun code, ils sont donc simplement invalidés.
    code_hash   = models.CharField(max_length=64, default='', editable=False)
    type        = models.CharField(max_length=20, choices=TYPES, default='login')
    created_at  = models.DateTimeField(auto_now_add=True)
    expires_at  = models.DateTimeField()
    used        = models.BooleanField(default=False)
    attempts    = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['telephone', '-created_at'])]

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + DUREE_VALIDITE
        super().save(*args, **kwargs)

    def is_valid(self):
        return (
            not self.used
            and self.expires_at > timezone.now()
            and self.attempts < TENTATIVES_MAX
        )

    def verifier(self, code):
        """Comparaison à temps constant, pour ne pas divulguer le code
        chiffre par chiffre via le temps de réponse."""
        return hmac.compare_digest(self.code_hash, hacher_code(code))

    def __str__(self):
        return f"OTP {self.telephone} [{self.type}] — {'utilisé' if self.used else 'actif'}"
