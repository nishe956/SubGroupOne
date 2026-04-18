from django.db import models
from django.conf import settings
from montures.models import Monture

class Commande(models.Model):
    STATUT_CHOICES = [
        ('en_attente', 'En attente'),
        ('en_preparation', 'En préparation'),
        ('expedier', 'Expédiée'),
        ('livrer', 'Livrée'),
    ]
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='commandes')
    monture = models.ForeignKey(Monture, on_delete=models.CASCADE)
    quantite = models.PositiveIntegerField(default=1)
    prix_total = models.DecimalField(max_digits=10, decimal_places=2)
    statut = models.CharField(max_length=20, choices=STATUT_CHOICES, default='en_attente')
    date_commande = models.DateTimeField(auto_now_add=True)
    adresse_livraison = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    
    # Détails de livraison et paiement
    TYPE_LIVRAISON_CHOICES = [
        ('expedition', 'Expédition'),
        ('domicile', 'Livraison Domicile'),
    ]
    MODE_PAIEMENT_CHOICES = [
        ('orange_money', 'Orange Money'),
        ('paypal', 'PayPal'),
        ('carte_bancaire', 'Carte Bancaire'),
        ('espece', 'Espèces à la livraison'),
    ]
    type_livraison = models.CharField(max_length=20, choices=TYPE_LIVRAISON_CHOICES, default='expedition')
    mode_paiement = models.CharField(max_length=20, choices=MODE_PAIEMENT_CHOICES, default='carte_bancaire')

    # Détail du paiement
    part_assurance = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    part_client = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    remise_famille = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    is_assurance_utilisee = models.BooleanField(default=False)
    
    # Snapshot Famille
    nb_membres_famille = models.PositiveIntegerField(default=1)
    nb_lunettes_famille = models.PositiveIntegerField(default=1)

    def __str__(self):
        email = self.user.email if self.user else "Utilisateur Inconnu"
        nom_monture = self.monture.nom if self.monture else "Produit Supprimé"
        return f"Commande #{self.id} - {email} - {nom_monture}"

    def save(self, *args, **kwargs):
        if not self.prix_total:
            self.prix_total = self.monture.prix * self.quantite
        super().save(*args, **kwargs)
