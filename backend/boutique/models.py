from django.db import models
from django.conf import settings


class BoutiqueOpticien(models.Model):
    opticien = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='boutique'
    )
    nom = models.CharField(max_length=200)
    slogan = models.CharField(max_length=300, blank=True)
    description = models.TextField(blank=True)
    adresse = models.TextField()
    telephone = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    logo = models.ImageField(upload_to='boutiques/', blank=True, null=True)
    actif = models.BooleanField(default=True)
    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nom
