from django.db import models
from django.utils import timezone
from datetime import timedelta
import random


def generer_otp():
    return str(random.randint(100000, 999999))


class OTPCode(models.Model):
    TYPES = [
        ('registration', 'Inscription'),
        ('login',        'Connexion'),
        ('reset',        'Réinitialisation'),
    ]

    telephone   = models.CharField(max_length=20)
    code        = models.CharField(max_length=6, default=generer_otp)
    type        = models.CharField(max_length=20, choices=TYPES, default='login')
    created_at  = models.DateTimeField(auto_now_add=True)
    expires_at  = models.DateTimeField()
    used        = models.BooleanField(default=False)
    attempts    = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(minutes=10)
        super().save(*args, **kwargs)

    def is_valid(self):
        return not self.used and self.expires_at > timezone.now() and self.attempts < 3

    def __str__(self):
        return f"OTP {self.telephone} [{self.type}] — {'utilisé' if self.used else 'actif'}"
