"""Limites de débit dédiées aux endpoints sensibles ou coûteux.

Deux principes :

1. L'identification par IP passe par `REMOTE_ADDR` sauf si l'application est
   explicitement déclarée derrière un proxy de confiance (`NUM_PROXIES`). Le
   comportement par défaut de DRF fait confiance à `X-Forwarded-For`, en-tête
   que n'importe quel client peut falsifier pour annuler toutes les limites.
2. Les endpoints d'authentification sont limités **par IP seule**, en plus du
   compteur par couple (IP, identifiant). Sans cela, le « password spraying »
   — un mot de passe courant essayé sur des milliers de comptes depuis une seule
   IP — n'est pas couvert.
"""
from rest_framework.throttling import SimpleRateThrottle


class ThrottleIP(SimpleRateThrottle):
    """Limite par adresse IP, quel que soit l'état d'authentification."""

    def get_cache_key(self, request, view):
        return self.cache_format % {
            'scope': self.scope,
            'ident': self.get_ident(request),
        }


class ThrottleConnexion(ThrottleIP):
    scope = 'connexion'


class ThrottleInscription(ThrottleIP):
    scope = 'inscription'


class ThrottleReset(ThrottleIP):
    scope = 'reset'


class ThrottleOTP(ThrottleIP):
    scope = 'otp'


class ThrottleUtilisateur(SimpleRateThrottle):
    """Limite par utilisateur authentifié, avec repli sur l'IP."""

    def get_cache_key(self, request, view):
        ident = (
            request.user.pk
            if request.user and request.user.is_authenticated
            else self.get_ident(request)
        )
        return self.cache_format % {'scope': self.scope, 'ident': ident}


class ThrottleOCR(ThrottleUtilisateur):
    """Chaque appel est facturé par le fournisseur d'IA : quota par compte."""
    scope = 'ocr'


class ThrottleInvitation(ThrottleUtilisateur):
    """Envoi d'emails vers des adresses arbitraires : quota strict par compte."""
    scope = 'invitation'


class ThrottleEssai(ThrottleUtilisateur):
    """Décodage d'image et inférence MediaPipe : coûteux en CPU et en mémoire."""
    scope = 'essai'
