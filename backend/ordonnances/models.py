from django.db import models
from django.conf import settings

class Ordonnance(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='ordonnances')
    image = models.ImageField(upload_to='ordonnances/', blank=True, null=True)
    texte_extrait = models.TextField(blank=True)
    date_scan = models.DateTimeField(auto_now_add=True)
    sphere_od = models.FloatField(null=True, blank=True)
    cylindre_od = models.FloatField(null=True, blank=True)
    axe_od = models.FloatField(null=True, blank=True)
    sphere_og = models.FloatField(null=True, blank=True)
    cylindre_og = models.FloatField(null=True, blank=True)
    axe_og = models.FloatField(null=True, blank=True)
    addition = models.FloatField(null=True, blank=True)

    def __str__(self):
        email = self.user.email if self.user else "Utilisateur Inconnu"
        return f"Ordonnance #{self.id} - {email} ({self.date_scan.date()})"
