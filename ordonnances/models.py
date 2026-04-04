from django.db import models
from users.models import User

class Ordonnance(models.Model):
    
    client = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='ordonnances'
    )
    image = models.ImageField(upload_to='ordonnances/')
    
    # Données extraites automatiquement par OCR
    oeil_droit_sphere = models.FloatField(blank=True, null=True)
    oeil_droit_cylindre = models.FloatField(blank=True, null=True)
    oeil_droit_axe = models.FloatField(blank=True, null=True)
    oeil_gauche_sphere = models.FloatField(blank=True, null=True)
    oeil_gauche_cylindre = models.FloatField(blank=True, null=True)
    oeil_gauche_axe = models.FloatField(blank=True, null=True)
    
    date_upload = models.DateTimeField(auto_now_add=True)
    validee = models.BooleanField(default=False)

    def __str__(self):
        return f"Ordonnance de {self.client.username}"