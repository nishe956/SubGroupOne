from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):

    # Les rôles possibles dans notre application
    ROLE_CHOICES = [
        ('client', 'Client'),
        ('opticien', 'Opticien'),
        ('admin', 'Administrateur'),
    ]

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default='client'
    )

    # Validation des comptes opticiens par un administrateur.
    # 'approuve' par défaut : clients, admin et comptes existants ne sont pas impactés.
    STATUT_VALIDATION_CHOICES = [
        ('approuve', 'Approuvé'),
        ('en_attente', 'En attente de validation'),
        ('rejete', 'Rejeté'),
    ]
    statut_validation = models.CharField(
        max_length=20,
        choices=STATUT_VALIDATION_CHOICES,
        default='approuve',
    )
    telephone = models.CharField(max_length=20, blank=True)
    adresse = models.TextField(blank=True)
    date_naissance = models.DateField(null=True, blank=True)
    compagnie_assurance = models.ForeignKey(
        'assurance.CompagnieAssurance',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='assures',
    )
    numero_police = models.CharField(max_length=100, blank=True)

    def __str__(self):
        return f"{self.username} ({self.role})"
