from html import escape

from django.core.mail import EmailMultiAlternatives
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


def _send(sujet, texte, html, destinataire):
    try:
        msg = EmailMultiAlternatives(
            subject=sujet,
            body=texte,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[destinataire],
        )
        msg.attach_alternative(html, "text/html")
        msg.send(fail_silently=False)
    except Exception as exc:
        logger.error("Erreur envoi email utilisateur : %s", exc)


def envoyer_email_reset_password(user, lien):
    email = user.email
    if not email:
        return

    nom = user.get_full_name() or user.username
    sujet = "[Lunette Pro] Réinitialisation de votre mot de passe"

    texte = (
        f"Bonjour {nom},\n\n"
        f"Vous avez demandé la réinitialisation de votre mot de passe.\n"
        f"Cliquez sur le lien suivant pour en choisir un nouveau (valable 24h) :\n\n"
        f"{lien}\n\n"
        f"Si vous n'êtes pas à l'origine de cette demande, ignorez cet email : "
        f"votre mot de passe actuel reste inchangé.\n\n"
        f"L'équipe Lunette Pro"
    )

    html = f"""
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f9;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08);">

        <!-- En-tête -->
        <tr>
          <td style="background:linear-gradient(135deg,#4f46e5,#7c3aed);padding:32px 40px;text-align:center;">
            <p style="margin:0;color:#e0e7ff;font-size:13px;letter-spacing:1px;">LUNETTE PRO</p>
            <h1 style="margin:8px 0 0;color:#fff;font-size:22px;">Réinitialisation du mot de passe</h1>
          </td>
        </tr>

        <!-- Corps -->
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 16px;font-size:16px;color:#111827;">Bonjour <strong>{nom}</strong>,</p>
            <p style="margin:0 0 24px;font-size:15px;color:#374151;line-height:1.6;">
              Vous avez demandé la réinitialisation de votre mot de passe. Cliquez sur le
              bouton ci-dessous pour en choisir un nouveau. Ce lien est valable 24 heures.
            </p>

            <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
              <tr>
                <td align="center">
                  <a href="{lien}" style="display:inline-block;background:#4f46e5;color:#fff;text-decoration:none;font-size:15px;font-weight:700;padding:14px 32px;border-radius:10px;">
                    Choisir un nouveau mot de passe
                  </a>
                </td>
              </tr>
            </table>

            <p style="margin:0;font-size:13px;color:#6b7280;line-height:1.6;">
              Si vous n'êtes pas à l'origine de cette demande, ignorez cet email :
              votre mot de passe actuel reste inchangé.
            </p>
          </td>
        </tr>

        <!-- Pied -->
        <tr>
          <td style="background:#f9fafb;padding:20px 40px;text-align:center;border-top:1px solid #e5e7eb;">
            <p style="margin:0;font-size:12px;color:#9ca3af;">© Lunette Pro — Merci pour votre confiance</p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
"""
    _send(sujet, texte, html, email)


def envoyer_email_demande_opticien(opticien, boutique=None):
    """Prévient les administrateurs qu'un opticien attend une validation.

    Sans cette notification, une demande pouvait rester en attente indéfiniment :
    rien n'avertissait l'administrateur, qui devait penser à consulter la page.
    """
    from .models import User

    destinataires = list(
        User.objects.filter(role='admin', is_active=True)
        .exclude(email='')
        .values_list('email', flat=True)
    )
    if not destinataires:
        logger.warning(
            "Demande opticien %s : aucun administrateur avec une adresse email.",
            opticien.pk,
        )
        return

    nom = opticien.get_full_name() or opticien.username
    nom_boutique = getattr(boutique, 'nom', '') or '—'
    lien = f"{settings.FRONTEND_URL}/admin/opticiens"

    sujet = f"[Lunette Pro] Nouvelle demande de compte opticien — {nom}"

    texte = (
        f"Une nouvelle demande de compte opticien vient d'être déposée.\n\n"
        f"Nom       : {nom}\n"
        f"Identifiant : {opticien.username}\n"
        f"Email     : {opticien.email or '—'}\n"
        f"Téléphone : {opticien.telephone or '—'}\n"
        f"Boutique  : {nom_boutique}\n\n"
        f"Le compte reste inactif tant qu'il n'a pas été approuvé.\n"
        f"Traiter la demande : {lien}\n\n"
        f"L'équipe Lunette Pro"
    )

    html = f"""
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f9;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08);">
        <tr>
          <td style="background:linear-gradient(135deg,#d97706,#b45309);padding:32px 40px;text-align:center;">
            <p style="margin:0;color:#fde68a;font-size:13px;letter-spacing:1px;">LUNETTE PRO — ADMINISTRATION</p>
            <h1 style="margin:8px 0 0;color:#fff;font-size:22px;">Nouvelle demande opticien</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 24px;font-size:15px;color:#374151;line-height:1.6;">
              Une demande de compte opticien vient d'être déposée. Le compte
              <strong>reste inactif</strong> tant qu'il n'a pas été approuvé.
            </p>
            <table width="100%" cellpadding="10" cellspacing="0"
                   style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:8px;margin-bottom:24px;">
              <tr><td style="font-size:13px;color:#6b7280;">Nom</td>
                  <td style="font-size:13px;color:#111827;font-weight:700;text-align:right;">{escape(nom)}</td></tr>
              <tr><td style="font-size:13px;color:#6b7280;">Identifiant</td>
                  <td style="font-size:13px;color:#111827;text-align:right;">{escape(opticien.username)}</td></tr>
              <tr><td style="font-size:13px;color:#6b7280;">Email</td>
                  <td style="font-size:13px;color:#111827;text-align:right;">{escape(opticien.email or '—')}</td></tr>
              <tr><td style="font-size:13px;color:#6b7280;">Téléphone</td>
                  <td style="font-size:13px;color:#111827;text-align:right;">{escape(opticien.telephone or '—')}</td></tr>
              <tr><td style="font-size:13px;color:#6b7280;">Boutique</td>
                  <td style="font-size:13px;color:#111827;text-align:right;">{escape(nom_boutique)}</td></tr>
            </table>
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr><td align="center">
                <a href="{lien}" style="display:inline-block;background:#d97706;color:#fff;text-decoration:none;font-size:15px;font-weight:700;padding:14px 32px;border-radius:10px;">
                  Traiter la demande
                </a>
              </td></tr>
            </table>
          </td>
        </tr>
        <tr>
          <td style="background:#f9fafb;padding:20px 40px;text-align:center;border-top:1px solid #e5e7eb;">
            <p style="margin:0;font-size:12px;color:#9ca3af;">© Lunette Pro</p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
"""
    for destinataire in destinataires:
        _send(sujet, texte, html, destinataire)
