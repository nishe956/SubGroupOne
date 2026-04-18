from django.contrib.auth.models import AbstractUser
from django.db import models

class Famille(models.Model):
    nom = models.CharField(max_length=100)
    chef_famille = models.ForeignKey('User', on_delete=models.CASCADE, related_name='familles_gerees')
    code_unique = models.CharField(max_length=10, unique=True)
    nb_membres = models.PositiveIntegerField(default=1)
    nb_lunettes_prevues = models.PositiveIntegerField(default=1)
    
    def __str__(self):
        return f"Famille {self.nom} ({self.code_unique})"

class PartnerAssurance(models.Model):
    nom = models.CharField(max_length=100)
    logo = models.ImageField(upload_to='assurances/', blank=True, null=True)
    contact = models.CharField(max_length=100, blank=True)
    taux_couverture_defaut = models.IntegerField(default=80) # ex: 80 pour 80%

    def __str__(self):
        return self.nom

class AuditLog(models.Model):
    user = models.ForeignKey('User', on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=255)
    details = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.timestamp} - {self.user} - {self.action}"

class User(AbstractUser):
    ROLE_CHOICES = [
        ('client', 'Client'),
        ('opticien', 'Opticien'),
        ('admin', 'Administrateur'),
    ]
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='client')
    telephone = models.CharField(max_length=20, blank=True)
    adresse = models.TextField(blank=True)
    
    # Informations Assurance et Famille
    assurance_nom = models.CharField(max_length=100, blank=True, null=True)
    assurance_numero = models.CharField(max_length=50, blank=True, null=True)
    famille = models.ForeignKey(Famille, on_delete=models.SET_NULL, null=True, blank=True, related_name='membres')
    code_famille = models.CharField(max_length=50, blank=True, null=True, help_text="Code obsolète, utilisez le lien famille.")

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username'] # username is still required by AbstractUser base, but we will handle it in serializers

    def __str__(self):
        return f"{self.email} ({self.role})"

class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    titre = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    type_notif = models.CharField(max_length=50) # 'commande', 'stock', 'ordonnance', 'system'
    timestamp = models.DateTimeField(auto_now_add=True)
    related_id = models.IntegerField(null=True, blank=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.user.email} - {self.titre}"
