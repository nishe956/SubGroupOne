"""Identification de l'appelant.

Centralisé ici parce que la règle est subtile et doit être identique partout :
`X-Forwarded-For` est un en-tête que le client contrôle. S'y fier sans proxy de
confiance devant l'application permet de faire varier son « identité » à chaque
requête et d'annuler toute limitation de débit.
"""
from django.conf import settings


def adresse_client(request):
    """Adresse IP de l'appelant, non falsifiable hors proxy de confiance."""
    if getattr(settings, 'TRUST_PROXY', False):
        transmis = request.META.get('HTTP_X_FORWARDED_FOR', '')
        if transmis:
            return transmis.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR', '')
