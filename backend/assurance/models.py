from django.db import models
from django.conf import settings


class CompagnieAssurance(models.Model):
    """Compagnies d'assurance partenaires."""
    nom              = models.CharField(max_length=200)
    code             = models.CharField(max_length=20, unique=True)
    taux_prise_charge = models.DecimalField(
        max_digits=5, decimal_places=2,
        help_text="Pourcentage pris en charge (ex: 80.00 = 80%)"
    )
    plafond_annuel   = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True,
        help_text="Plafond annuel de remboursement en CFA"
    )
    telephone        = models.CharField(max_length=20, blank=True)
    email            = models.EmailField(blank=True)
    adresse          = models.TextField(blank=True)
    active           = models.BooleanField(default=True)
    date_ajout       = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Compagnie assurance'
        ordering = ['nom']

    def __str__(self):
        return f"{self.nom} ({self.taux_prise_charge}%)"


class DemandeRemboursement(models.Model):
    """Demandes de remboursement liées à une commande."""
    STATUTS = [
        ('en_attente',  'En attente'),
        ('soumise',     "Soumise à l'assurance"),
        ('approuvee',   'Approuvée'),
        ('rejetee',     'Rejetée'),
        ('remboursee',  'Remboursée'),
    ]

    commande         = models.OneToOneField('commandes.Commande', on_delete=models.CASCADE, related_name='remboursement')
    compagnie        = models.ForeignKey(CompagnieAssurance, on_delete=models.SET_NULL, null=True)
    client           = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    numero_police    = models.CharField(max_length=100, blank=True)
    montant_total    = models.DecimalField(max_digits=10, decimal_places=2)
    montant_rembourse = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    montant_patient  = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    statut           = models.CharField(max_length=20, choices=STATUTS, default='en_attente')
    date_soumission  = models.DateTimeField(auto_now_add=True)
    date_traitement  = models.DateTimeField(null=True, blank=True)
    notes            = models.TextField(blank=True)

    class Meta:
        verbose_name = 'Demande de remboursement'
        ordering = ['-date_soumission']

    def __str__(self):
        return f"Remboursement commande #{self.commande_id} — {self.statut}"

    def calculer_montants(self):
        if self.compagnie:
            taux = float(self.compagnie.taux_prise_charge) / 100
            self.montant_rembourse = float(self.montant_total) * taux
            self.montant_patient   = float(self.montant_total) - float(self.montant_rembourse)
            # Appliquer le plafond
            if self.compagnie.plafond_annuel:
                self.montant_rembourse = min(float(self.montant_rembourse), float(self.compagnie.plafond_annuel))
                self.montant_patient   = float(self.montant_total) - float(self.montant_rembourse)
