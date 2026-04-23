from django.db import models
from django.conf import settings
from PIL import Image as PilImage
import os


def compress_image(image_field, max_size=(800, 800), quality=75):
    """Redimensionne et compresse une image uploadée."""
    img_path = image_field.path
    img = PilImage.open(img_path)
    if img.mode in ('RGBA', 'P'):
        img = img.convert('RGB')
    img.thumbnail(max_size, PilImage.LANCZOS)
    img.save(img_path, format='JPEG', quality=quality, optimize=True)


class Monture(models.Model):
    FORME_CHOICES = [
        ('ronde', 'Ronde'),
        ('carree', 'Carrée'),
        ('ovale', 'Ovale'),
        ('rectangulaire', 'Rectangulaire'),
    ]

    CATEGORIE_CHOICES = [
        ('adulte', 'Adulte'),
        ('enfant', 'Enfant'),
        ('sport', 'Sport'),
        ('luxe', 'Luxe'),
    ]

    nom         = models.CharField(max_length=100)
    marque      = models.CharField(max_length=100)
    prix        = models.DecimalField(max_digits=10, decimal_places=2)
    categorie   = models.CharField(max_length=20, choices=CATEGORIE_CHOICES, default='adulte')
    forme       = models.CharField(max_length=20, choices=FORME_CHOICES)
    couleur     = models.CharField(max_length=50)
    image       = models.ImageField(upload_to='montures/', blank=True, null=True)
    description = models.TextField(blank=True)
    stock       = models.IntegerField(default=0)
    disponible  = models.BooleanField(default=True)
    date_ajout  = models.DateTimeField(auto_now_add=True)
    ajoute_par  = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='montures_ajoutees',
        verbose_name='Ajouté par',
    )

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.image:
            try:
                compress_image(self.image)
            except Exception:
                pass

    def __str__(self):
        return f"{self.marque} - {self.nom}"

    def image_principale(self):
        """Retourne la première image galerie, ou l'image principale."""
        first = self.galerie.first()
        return first.image if first else self.image


class MontureImage(models.Model):
    """Images supplémentaires pour une monture (galerie)."""
    monture    = models.ForeignKey(Monture, on_delete=models.CASCADE, related_name='galerie')
    image      = models.ImageField(upload_to='montures/galerie/')
    ordre      = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['ordre', 'created_at']

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.image:
            try:
                compress_image(self.image)
            except Exception:
                pass

    def __str__(self):
        return f"Image {self.id} — {self.monture.nom}"
