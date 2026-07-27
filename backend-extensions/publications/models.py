from django.db import models
from django.conf import settings


class Publication(models.Model):
    CATEGORIES = [
        ('conseil', 'Conseil'),
        ('actualite', 'Actualité'),
        ('promotion', 'Promotion'),
        ('sante', 'Santé'),
        ('tendance', 'Tendance'),
    ]

    titre       = models.CharField(max_length=255)
    contenu     = models.TextField()
    resume      = models.CharField(max_length=500, blank=True)
    categorie   = models.CharField(max_length=20, choices=CATEGORIES, default='conseil')
    image       = models.ImageField(upload_to='publications/', blank=True, null=True)
    auteur      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='publications')
    date_creation   = models.DateTimeField(auto_now_add=True)
    date_modification = models.DateTimeField(auto_now=True)
    publie      = models.BooleanField(default=True)
    vues        = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['-date_creation']

    def __str__(self):
        return self.titre


class LikePublication(models.Model):
    publication = models.ForeignKey(Publication, on_delete=models.CASCADE, related_name='likes_set')
    user        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('publication', 'user')


class Commentaire(models.Model):
    publication = models.ForeignKey(Publication, on_delete=models.CASCADE, related_name='commentaires')
    auteur      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    contenu     = models.TextField()
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['date_creation']

    def __str__(self):
        return f"Commentaire de {self.auteur} sur {self.publication}"
