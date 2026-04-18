from django.db import models
from django.conf import settings
from montures.models import Monture

class EssaiVirtuel(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='essais')
    monture = models.ForeignKey(Monture, on_delete=models.CASCADE)
    image_utilisateur = models.ImageField(upload_to='essais/', blank=True, null=True)
    image_resultat = models.ImageField(upload_to='essais/resultats/', blank=True, null=True)
    date_essai = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Essai #{self.id} - {self.user.username} - {self.monture.nom}"
