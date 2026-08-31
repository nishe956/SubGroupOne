from django.conf import settings
from django.db import models


class Visite(models.Model):
    """Une page consultée côté public/client, base des statistiques de fréquentation.

    Aucune donnée personnelle n'est conservée : `visiteur` est un identifiant
    aléatoire généré par le navigateur (pas une adresse IP), qui sert uniquement
    à distinguer les visiteurs uniques.
    """

    chemin = models.CharField(max_length=255, db_index=True)

    # Renseigné quand la page consultée est la fiche d'une monture : permet de
    # savoir quels produits attirent l'attention, même sans achat.
    monture = models.ForeignKey(
        'montures.Monture',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='visites',
    )

    # Opticien propriétaire de la monture consultée. Dénormalisé à l'écriture pour
    # que chaque opticien ne voie que la fréquentation de ses propres produits,
    # même si la monture est supprimée plus tard.
    opticien = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='visites_recues',
    )

    # Nul pour un visiteur non connecté.
    utilisateur = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='visites',
    )

    visiteur = models.CharField(max_length=64, db_index=True)
    date = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-date']
        indexes = [
            models.Index(fields=['-date', 'opticien']),
        ]
        verbose_name = 'Visite'

    def __str__(self):
        return f"{self.chemin} — {self.date:%d/%m/%Y %H:%M}"
