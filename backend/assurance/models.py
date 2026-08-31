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
        """Répartit le montant entre l'assurance et le patient.

        Calcul en Decimal : les `float` introduisaient des erreurs d'arrondi sur
        des montants financiers stockés en DecimalField.
        """
        from decimal import Decimal, ROUND_HALF_UP

        if not self.compagnie:
            self.montant_rembourse = Decimal('0.00')
            self.montant_patient = Decimal(self.montant_total)
            return

        total = Decimal(self.montant_total)
        taux = Decimal(self.compagnie.taux_prise_charge) / Decimal('100')
        rembourse = total * taux

        if self.compagnie.plafond_annuel:
            rembourse = min(rembourse, Decimal(self.compagnie.plafond_annuel))

        # Le remboursement ne peut jamais dépasser le montant réellement payé.
        rembourse = max(Decimal('0'), min(rembourse, total))

        self.montant_rembourse = rembourse.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
        self.montant_patient = (total - self.montant_rembourse).quantize(
            Decimal('0.01'), rounding=ROUND_HALF_UP
        )
