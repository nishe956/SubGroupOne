import os
import uuid

from django.conf import settings
from django.core.files.storage import storages
from django.db import models

from users.models import User

EXTENSIONS_AUTORISEES = ('.jpg', '.jpeg', '.png', '.webp', '.gif', '.pdf')


def stockage_prive():
    """Stockage réservé aux documents médicaux.

    En production, il pointe vers un bucket privé distinct du bucket public du
    catalogue : les ordonnances ne doivent jamais atterrir derrière un domaine
    CDN accessible sans authentification.
    """
    return storages[settings.STOCKAGE_PRIVE]


def chemin_ordonnance(instance, filename):
    """Nom de fichier aléatoire.

    Le nom d'origine fourni par le client était conservé : il rendait les
    documents devinables (`ordonnance_test3.png`, `scan_2026.jpg`...) et pouvait
    contenir des séquences de traversée de répertoire.
    """
    extension = os.path.splitext(filename or '')[1].lower()
    if extension not in EXTENSIONS_AUTORISEES:
        extension = '.bin'
    return f"ordonnances/{uuid.uuid4().hex}{extension}"


class Ordonnance(models.Model):

    client = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='ordonnances'
    )
    image = models.ImageField(upload_to=chemin_ordonnance, storage=stockage_prive)

    # Données extraites automatiquement par OCR
    oeil_droit_sphere = models.FloatField(blank=True, null=True)
    oeil_droit_cylindre = models.FloatField(blank=True, null=True)
    oeil_droit_axe = models.FloatField(blank=True, null=True)
    oeil_gauche_sphere = models.FloatField(blank=True, null=True)
    oeil_gauche_cylindre = models.FloatField(blank=True, null=True)
    oeil_gauche_axe = models.FloatField(blank=True, null=True)

    date_upload = models.DateTimeField(auto_now_add=True)
    validee = models.BooleanField(default=False)

    class Meta:
        ordering = ['-date_upload']

    def __str__(self):
        return f"Ordonnance de {self.client.username}"
