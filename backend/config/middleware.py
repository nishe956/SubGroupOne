"""Middleware d'en-têtes de sécurité HTTP.

Attention : ce middleware ne couvre que les réponses de l'API Django. Le SPA
React est servi par Vercel et reçoit ses propres en-têtes via `frontend/vercel.json` —
c'est là que la CSP protège réellement du JavaScript injecté.
"""
from django.conf import settings
from django.http import HttpResponse


class HealthCheckMiddleware:
    """Répond à la sonde de vivacité avant toute autre couche.

    Placé en tête de MIDDLEWARE, ce court-circuit contourne trois mécanismes qui
    font échouer une sonde locale en production, chacun suffisant à lui seul :

    - ALLOWED_HOSTS : la sonde interroge ``127.0.0.1``, qui ne figure pas dans la
      liste des domaines publics — Django répondrait 400 DisallowedHost ;
    - SECURE_SSL_REDIRECT : sans en-tête ``X-Forwarded-Proto: https``, Django
      renvoie une 301 vers HTTPS que la sonde ne peut pas suivre ;
    - la limitation de débit DRF (100 requêtes anonymes par jour et par IP) :
      une sonde toutes les 30 s en émet 2880, donc 429 au bout d'environ
      cinquante minutes — et le conteneur était marqué en échec pour de bon.

    La réponse ne touche ni la base ni le cache : c'est une sonde de vivacité,
    elle doit dire « le process répond », pas « toutes les dépendances vont bien ».
    """

    CHEMINS = frozenset(('/healthz', '/healthz/'))

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # `request.path` n'appelle pas `get_host()` : aucune validation d'hôte
        # n'est déclenchée avant que la réponse ne parte.
        if request.path in self.CHEMINS:
            return HttpResponse('ok', content_type='text/plain')
        return self.get_response(request)


class SecurityHeadersMiddleware:
    """Ajoute les en-têtes de sécurité sur chaque réponse de l'API."""

    def __init__(self, get_response):
        self.get_response = get_response
        self.debug = settings.DEBUG

        # L'API ne renvoie que du JSON et des fichiers : aucun script, aucun
        # style, aucune iframe. La politique la plus stricte est donc applicable
        # sans rien casser, y compris sur les pages d'erreur DRF.
        self.csp = (
            "default-src 'none'; "
            "frame-ancestors 'none'; "
            "base-uri 'none'; "
            "form-action 'none'; "
            "img-src 'self' data:; "
            "style-src 'self' 'unsafe-inline'; "
            "script-src 'self'"
        )
        if not self.debug:
            self.csp += "; upgrade-insecure-requests"

    def __call__(self, request):
        response = self.get_response(request)

        # Interdit l'affichage de l'app dans une iframe (anti-clickjacking).
        response['X-Frame-Options'] = 'DENY'

        # Empêche le navigateur de deviner le type MIME.
        response['X-Content-Type-Options'] = 'nosniff'

        # Politique de référents : ne pas fuiter les URLs vers des tiers.
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'

        # Coupe l'accès aux capteurs pour tout contenu servi par l'API.
        response['Permissions-Policy'] = (
            'geolocation=(), camera=(), microphone=(), payment=(), usb=()'
        )

        response.setdefault('Content-Security-Policy', self.csp)

        # X-XSS-Protection est volontairement absent : l'en-tête est obsolète,
        # retiré des navigateurs modernes, et son filtre a introduit ses propres
        # vulnérabilités. La CSP le remplace.

        if not self.debug:
            response['Strict-Transport-Security'] = (
                'max-age=31536000; includeSubDomains; preload'
            )

        return response
