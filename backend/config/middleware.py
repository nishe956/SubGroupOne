"""Middleware d'en-têtes de sécurité HTTP."""
import os


class SecurityHeadersMiddleware:
    """
    Ajoute les en-têtes de sécurité sur chaque réponse.
    Protège contre XSS, clickjacking, MIME sniffing et injections.
    """
    def __init__(self, get_response):
        self.get_response = get_response
        self.debug = os.getenv('DEBUG', 'False').lower() in ('true', '1')

    def __call__(self, request):
        response = self.get_response(request)

        # Interdit l'affichage de l'app dans une iframe (anti-clickjacking)
        response['X-Frame-Options'] = 'DENY'

        # Empêche le navigateur de deviner le type MIME
        response['X-Content-Type-Options'] = 'nosniff'

        # Active la protection XSS du navigateur
        response['X-XSS-Protection'] = '1; mode=block'

        # Politique de référents : n'envoyer que l'origine
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'

        # Content Security Policy
        if self.debug:
            # En dev : permissif pour le hot-reload Vite
            csp = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: blob: https://nominatim.openstreetmap.org https://maps.google.com https://maps.gstatic.com; "
                "frame-src https://maps.google.com; "
                "connect-src 'self' https://nominatim.openstreetmap.org ws://localhost:*;"
            )
        else:
            # En production : strict
            csp = (
                "default-src 'self'; "
                "script-src 'self'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: blob: https://nominatim.openstreetmap.org https://maps.google.com https://maps.gstatic.com; "
                "frame-src https://maps.google.com; "
                "connect-src 'self' https://nominatim.openstreetmap.org; "
                "upgrade-insecure-requests;"
            )

        response['Content-Security-Policy'] = csp

        # En production : forcer HTTPS
        if not self.debug:
            response['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'

        return response
