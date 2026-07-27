from django.db import models

class Monture(models.Model):
    
    FORME_CHOICES = [
        ('ronde', 'Ronde'),
        ('carree', 'Carrée'),
        ('ovale', 'Ovale'),
        ('rectangulaire', 'Rectangulaire'),
    ]
    
    nom = models.CharField(max_length=100)
    marque = models.CharField(max_length=100)
    prix = models.DecimalField(max_digits=10, decimal_places=2)
    forme = models.CharField(max_length=20, choices=FORME_CHOICES)
    couleur = models.CharField(max_length=50)
    image = models.ImageField(upload_to='montures/', blank=True, null=True)
    description = models.TextField(blank=True)
    stock = models.IntegerField(default=0)
    disponible = models.BooleanField(default=True)
    date_ajout = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.marque} - {self.nom}"