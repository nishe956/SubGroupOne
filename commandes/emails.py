from django.core.mail import EmailMultiAlternatives
from django.conf import settings
from django.utils.timezone import localtime
import logging

logger = logging.getLogger(__name__)


def _nom_client(commande):
    u = commande.client
    return u.get_full_name() or u.username


def _format_prix(montant):
    return f"{int(montant):,} F CFA".replace(",", ".")


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
        logger.error("Erreur envoi email commande : %s", exc)


# ---------------------------------------------------------------------------
# 1. Commande reçue (envoyée juste après la création)
# ---------------------------------------------------------------------------
def envoyer_email_commande_recue(commande):
    email = commande.client.email
    if not email:
        return

    nom    = _nom_client(commande)
    montant = _format_prix(commande.prix_total)
    monture = commande.monture
    date    = localtime(commande.date_commande).strftime("%d/%m/%Y à %H:%M")
    ref     = f"CMD-{commande.id:06d}"

    sujet = f"[Lunette Pro] Commande {ref} bien reçue"

    texte = (
        f"Bonjour {nom},\n\n"
        f"Nous avons bien reçu votre commande {ref} du {date}.\n"
        f"Monture : {monture.marque} — {monture.nom}\n"
        f"Montant : {montant}\n\n"
        f"Elle est actuellement en attente de validation par votre opticien.\n"
        f"Vous recevrez un autre email dès qu'elle sera traitée.\n\n"
        f"Merci pour votre confiance,\nL'équipe Lunette Pro"
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
            <h1 style="margin:8px 0 0;color:#fff;font-size:22px;">Commande reçue ✓</h1>
          </td>
        </tr>

        <!-- Corps -->
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 16px;font-size:16px;color:#111827;">Bonjour <strong>{nom}</strong>,</p>
            <p style="margin:0 0 24px;font-size:15px;color:#374151;line-height:1.6;">
              Nous avons bien reçu votre commande. Elle est actuellement
              <strong style="color:#d97706;">en attente de validation</strong> par votre opticien.
              Vous serez notifié(e) par email dès qu'elle sera traitée.
            </p>

            <!-- Récap commande -->
            <table width="100%" cellpadding="12" cellspacing="0"
                   style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:8px;margin-bottom:24px;">
              <tr>
                <td style="font-size:13px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Référence</td>
                <td style="font-size:13px;color:#111827;font-weight:700;border-bottom:1px solid #e5e7eb;text-align:right;">{ref}</td>
              </tr>
              <tr>
                <td style="font-size:13px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Date</td>
                <td style="font-size:13px;color:#111827;border-bottom:1px solid #e5e7eb;text-align:right;">{date}</td>
              </tr>
              <tr>
                <td style="font-size:13px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Marque</td>
                <td style="font-size:13px;color:#111827;border-bottom:1px solid #e5e7eb;text-align:right;">{monture.marque}</td>
              </tr>
              <tr>
                <td style="font-size:13px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Monture</td>
                <td style="font-size:13px;color:#111827;border-bottom:1px solid #e5e7eb;text-align:right;">{monture.nom}</td>
              </tr>
              <tr>
                <td style="font-size:14px;color:#111827;font-weight:700;">Montant total</td>
                <td style="font-size:14px;color:#4f46e5;font-weight:700;text-align:right;">{montant}</td>
              </tr>
            </table>

            <p style="margin:0;font-size:14px;color:#6b7280;line-height:1.6;">
              Si vous n'êtes pas à l'origine de cette commande, veuillez nous contacter immédiatement.
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


# ---------------------------------------------------------------------------
# 2. Commande validée + reçu d'achat
# ---------------------------------------------------------------------------
def envoyer_email_commande_validee(commande):
    email = commande.client.email
    if not email:
        return

    nom     = _nom_client(commande)
    montant = _format_prix(commande.prix_total)
    monture = commande.monture
    date    = localtime(commande.date_commande).strftime("%d/%m/%Y à %H:%M")
    ref     = f"CMD-{commande.id:06d}"

    methode_label = {
        'carte_bancaire': 'Carte bancaire',
        'orange_money':   'Orange Money',
        'wave':           'Wave',
    }.get(commande.methode_paiement, commande.methode_paiement or '—')

    sujet = f"[Lunette Pro] Commande {ref} validée — votre reçu"

    texte = (
        f"Bonjour {nom},\n\n"
        f"Bonne nouvelle ! Votre commande {ref} a été validée.\n\n"
        f"--- REÇU D'ACHAT ---\n"
        f"Référence     : {ref}\n"
        f"Date          : {date}\n"
        f"Monture       : {monture.marque} — {monture.nom}\n"
        f"Forme         : {monture.forme}\n"
        f"Couleur       : {monture.couleur}\n"
        f"Mode paiement : {methode_label}\n"
        f"Montant payé  : {montant}\n"
        f"--------------------\n\n"
        f"Votre opticien prépare votre commande. Vous serez contacté(e) pour la livraison.\n\n"
        f"Merci,\nL'équipe Lunette Pro"
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
          <td style="background:linear-gradient(135deg,#059669,#10b981);padding:32px 40px;text-align:center;">
            <p style="margin:0;color:#d1fae5;font-size:13px;letter-spacing:1px;">LUNETTE PRO</p>
            <h1 style="margin:8px 0 0;color:#fff;font-size:22px;">Commande validée ✓</h1>
          </td>
        </tr>

        <!-- Corps -->
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 16px;font-size:16px;color:#111827;">Bonjour <strong>{nom}</strong>,</p>
            <p style="margin:0 0 28px;font-size:15px;color:#374151;line-height:1.6;">
              Bonne nouvelle ! Votre commande a été <strong style="color:#059669;">validée</strong>.
              Votre opticien prépare votre commande et vous contactera pour la livraison.
            </p>

            <!-- Reçu -->
            <table width="100%" cellpadding="0" cellspacing="0" style="border:2px solid #e5e7eb;border-radius:10px;overflow:hidden;margin-bottom:28px;">
              <!-- Titre reçu -->
              <tr>
                <td colspan="2" style="background:#f9fafb;padding:14px 20px;border-bottom:2px solid #e5e7eb;">
                  <p style="margin:0;font-size:13px;font-weight:700;color:#374151;text-transform:uppercase;letter-spacing:1px;">Reçu d'achat</p>
                </td>
              </tr>
              <tr>
                <td style="padding:12px 20px;font-size:13px;color:#6b7280;border-bottom:1px solid #f3f4f6;">Référence</td>
                <td style="padding:12px 20px;font-size:13px;color:#111827;font-weight:700;text-align:right;border-bottom:1px solid #f3f4f6;">{ref}</td>
              </tr>
              <tr>
                <td style="padding:12px 20px;font-size:13px;color:#6b7280;border-bottom:1px solid #f3f4f6;">Date de commande</td>
                <td style="padding:12px 20px;font-size:13px;color:#111827;text-align:right;border-bottom:1px solid #f3f4f6;">{date}</td>
              </tr>
              <tr>
                <td style="padding:12px 20px;font-size:13px;color:#6b7280;border-bottom:1px solid #f3f4f6;">Marque</td>
                <td style="padding:12px 20px;font-size:13px;color:#111827;text-align:right;border-bottom:1px solid #f3f4f6;">{monture.marque}</td>
              </tr>
              <tr>
                <td style="padding:12px 20px;font-size:13px;color:#6b7280;border-bottom:1px solid #f3f4f6;">Monture</td>
                <td style="padding:12px 20px;font-size:13px;color:#111827;text-align:right;border-bottom:1px solid #f3f4f6;">{monture.nom}</td>
              </tr>
              <tr>
                <td style="padding:12px 20px;font-size:13px;color:#6b7280;border-bottom:1px solid #f3f4f6;">Forme</td>
                <td style="padding:12px 20px;font-size:13px;color:#111827;text-align:right;border-bottom:1px solid #f3f4f6;">{monture.forme}</td>
              </tr>
              <tr>
                <td style="padding:12px 20px;font-size:13px;color:#6b7280;border-bottom:1px solid #f3f4f6;">Couleur</td>
                <td style="padding:12px 20px;font-size:13px;color:#111827;text-align:right;border-bottom:1px solid #f3f4f6;">{monture.couleur}</td>
              </tr>
              <tr>
                <td style="padding:12px 20px;font-size:13px;color:#6b7280;border-bottom:1px solid #f3f4f6;">Mode de paiement</td>
                <td style="padding:12px 20px;font-size:13px;color:#111827;text-align:right;border-bottom:1px solid #f3f4f6;">{methode_label}</td>
              </tr>
              <!-- Total -->
              <tr style="background:#f0fdf4;">
                <td style="padding:16px 20px;font-size:15px;color:#065f46;font-weight:700;">Montant total payé</td>
                <td style="padding:16px 20px;font-size:18px;color:#059669;font-weight:700;text-align:right;">{montant}</td>
              </tr>
            </table>

            <p style="margin:0;font-size:14px;color:#6b7280;line-height:1.6;">
              Conservez cet email comme preuve d'achat.
              Pour toute question, contactez votre opticien.
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


# ---------------------------------------------------------------------------
# 3. Commande rejetée
# ---------------------------------------------------------------------------
def envoyer_email_commande_rejetee(commande):
    email = commande.client.email
    if not email:
        return

    nom  = _nom_client(commande)
    ref  = f"CMD-{commande.id:06d}"
    date = localtime(commande.date_commande).strftime("%d/%m/%Y")
    note = commande.notes or "Aucune précision fournie."

    sujet = f"[Lunette Pro] Commande {ref} — non confirmée"

    texte = (
        f"Bonjour {nom},\n\n"
        f"Nous vous informons que votre commande {ref} du {date} n'a pas pu être confirmée.\n\n"
        f"Motif : {note}\n\n"
        f"Si vous avez des questions, contactez votre opticien.\n"
        f"Vous pouvez passer une nouvelle commande depuis le catalogue.\n\n"
        f"Cordialement,\nL'équipe Lunette Pro"
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
          <td style="background:linear-gradient(135deg,#dc2626,#ef4444);padding:32px 40px;text-align:center;">
            <p style="margin:0;color:#fee2e2;font-size:13px;letter-spacing:1px;">LUNETTE PRO</p>
            <h1 style="margin:8px 0 0;color:#fff;font-size:22px;">Commande non confirmée</h1>
          </td>
        </tr>

        <!-- Corps -->
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 16px;font-size:16px;color:#111827;">Bonjour <strong>{nom}</strong>,</p>
            <p style="margin:0 0 24px;font-size:15px;color:#374151;line-height:1.6;">
              Nous vous informons que votre commande <strong>{ref}</strong> du {date}
              n'a pas pu être confirmée.
            </p>

            <!-- Motif -->
            <table width="100%" cellpadding="16" cellspacing="0"
                   style="background:#fff5f5;border:1px solid #fecaca;border-radius:8px;margin-bottom:24px;">
              <tr>
                <td>
                  <p style="margin:0 0 6px;font-size:12px;color:#991b1b;font-weight:700;text-transform:uppercase;letter-spacing:1px;">Motif</p>
                  <p style="margin:0;font-size:14px;color:#374151;line-height:1.6;">{note}</p>
                </td>
              </tr>
            </table>

            <p style="margin:0 0 12px;font-size:14px;color:#374151;line-height:1.6;">
              Pour toute question, n'hésitez pas à contacter directement votre opticien.
              Vous pouvez également passer une nouvelle commande depuis notre catalogue.
            </p>
            <p style="margin:0;font-size:14px;color:#6b7280;">
              Nous espérons vous retrouver bientôt.
            </p>
          </td>
        </tr>

        <!-- Pied -->
        <tr>
          <td style="background:#f9fafb;padding:20px 40px;text-align:center;border-top:1px solid #e5e7eb;">
            <p style="margin:0;font-size:12px;color:#9ca3af;">© Lunette Pro — Pour toute assistance, contactez votre opticien</p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
"""
    _send(sujet, texte, html, email)
