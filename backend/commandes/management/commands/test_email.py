"""
Envoie un email de test pour vérifier la configuration SMTP.

Usage :
    python manage.py test_email destinataire@example.com
"""
from django.core.management.base import BaseCommand, CommandError
from django.core.mail import EmailMultiAlternatives
from django.conf import settings


class Command(BaseCommand):
    help = "Envoie un email de test pour vérifier la configuration SMTP."

    def add_arguments(self, parser):
        parser.add_argument('destinataire', type=str, help="Adresse email de destination")

    def handle(self, *args, **options):
        destinataire = options['destinataire']
        backend = settings.EMAIL_BACKEND

        self.stdout.write(f"Backend actif   : {backend}")
        self.stdout.write(f"Expéditeur      : {settings.DEFAULT_FROM_EMAIL}")
        if 'console' in backend:
            self.stdout.write(self.style.WARNING(
                "⚠ Backend CONSOLE : le mail sera affiché ci-dessous mais NON envoyé.\n"
                "  Renseigne EMAIL_HOST dans .env pour un envoi réel."
            ))
        else:
            self.stdout.write(f"Serveur SMTP    : {settings.EMAIL_HOST}:{settings.EMAIL_PORT} "
                              f"(TLS={getattr(settings, 'EMAIL_USE_TLS', False)}, "
                              f"SSL={getattr(settings, 'EMAIL_USE_SSL', False)})")

        sujet = "[Lunette Pro] Test de configuration email"
        texte = (
            "Ceci est un email de test envoyé depuis Lunette Pro.\n\n"
            "Si vous le recevez, la configuration SMTP fonctionne correctement."
        )
        html = """
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;">
          <div style="background:linear-gradient(135deg,#4f46e5,#7c3aed);padding:24px;border-radius:12px 12px 0 0;text-align:center;">
            <h1 style="color:#fff;margin:0;font-size:20px;">Lunette Pro ✓</h1>
          </div>
          <div style="border:1px solid #e5e7eb;border-top:0;border-radius:0 0 12px 12px;padding:24px;">
            <p style="color:#111827;font-size:15px;">Ceci est un <strong>email de test</strong>.</p>
            <p style="color:#374151;font-size:14px;">Si vous le recevez, votre configuration SMTP
            fonctionne correctement. Les reçus de commande seront bien délivrés à vos clients.</p>
          </div>
        </div>
        """

        try:
            msg = EmailMultiAlternatives(
                subject=sujet,
                body=texte,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[destinataire],
            )
            msg.attach_alternative(html, "text/html")
            envoyes = msg.send(fail_silently=False)
        except Exception as exc:
            raise CommandError(f"❌ Échec de l'envoi : {exc}")

        if envoyes:
            self.stdout.write(self.style.SUCCESS(
                f"✓ Email envoyé à {destinataire}. Vérifie ta boîte de réception (et les spams)."
            ))
        else:
            self.stdout.write(self.style.ERROR("❌ Aucun email envoyé (0 message)."))
