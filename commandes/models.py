from django.db import models
from users.models import User
from montures.models import Monture
from ordonnances.models import Ordonnance

class Commande(models.Model):
    
    STATUT_CHOICES = [
        ('en_attente', 'En attente'),
        ('validee', 'Validée'),
        ('rejetee', 'Rejetée'),
        ('en_preparation', 'En préparation'),
        ('livree', 'Livrée'),
    ]
    
    client = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='commandes'
    )
    monture = models.ForeignKey(
        Monture, 
        on_delete=models.CASCADE
    )
    ordonnance = models.ForeignKey(
        Ordonnance, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    statut = models.CharField(
        max_length=20, 
        choices=STATUT_CHOICES, 
        default='en_attente'
    )
    
    # Informations assurance
    numero_assurance = models.CharField(max_length=100, blank=True)
    nom_assurance = models.CharField(max_length=100, blank=True)
    
    opticien = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='commandes_recues'
    )

    METHODE_PAIEMENT_CHOICES = [
        ('carte_bancaire', 'Carte bancaire'),
        ('orange_money', 'Orange Money'),
        ('wave', 'Wave'),
    ]

    methode_paiement = models.CharField(
        max_length=20,
        choices=METHODE_PAIEMENT_CHOICES,
        blank=True,
        default='',
    )
    telephone_paiement = models.CharField(max_length=20, blank=True)

    adresse_livraison = models.TextField(blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    type_verre = models.CharField(max_length=50, blank=True)
    options_verres = models.JSONField(default=list, blank=True)
    prix_verres = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    prix_total = models.DecimalField(max_digits=10, decimal_places=2)
    date_commande = models.DateTimeField(auto_now_add=True)
    date_mise_a_jour = models.DateTimeField(auto_now=True)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"Commande {self.id} - {self.client.username}"