"""
Tâche planifiée : envoi automatique des messages d'anniversaire.
Exécutée chaque jour à l'heure configurée par chaque opticien.
"""
import logging
from django.utils import timezone
from django.contrib.auth import get_user_model

logger = logging.getLogger(__name__)
User = get_user_model()


def envoyer_anniversaires_auto():
    """
    Parcourt tous les opticiens ayant activé l'envoi auto,
    trouve leurs clients dont c'est l'anniversaire aujourd'hui,
    et envoie le message personnalisé.
    """
    from .models import ConfigAutoAnniversaire, HistoriqueSMS
    from sms_otp.sms_service import envoyer_sms

    today = timezone.now().date()
    configs = ConfigAutoAnniversaire.objects.filter(actif=True).select_related('opticien')

    total_envoyes = 0

    for config in configs:
        opticien = config.opticien

        # Clients de cet opticien dont c'est l'anniversaire aujourd'hui
        clients_anniv = User.objects.filter(
            role='client',
            commandes__monture__ajoute_par=opticien,
            date_naissance__month=today.month,
            date_naissance__day=today.day,
        ).distinct()

        for client in clients_anniv:
            # Éviter un double-envoi le même jour
            deja_envoye = HistoriqueSMS.objects.filter(
                destinataire=client,
                type_message='anniversaire',
                date_envoi__date=today,
                envoye_par=opticien,
            ).exists()

            if deja_envoye:
                continue

            prenom = client.first_name or client.username
            message = config.message_template.format(prenom=prenom)

            sent = False
            if client.telephone:
                sent = envoyer_sms(client.telephone, message)

            HistoriqueSMS.objects.create(
                destinataire=client,
                telephone=client.telephone or '',
                message=message,
                type_message='anniversaire',
                envoye=sent,
                envoye_par=opticien,
            )

            if sent:
                total_envoyes += 1
                logger.info(f"[Anniversaire AUTO] SMS envoyé à {client.username} par {opticien.username}")

    logger.info(f"[Anniversaire AUTO] {total_envoyes} SMS envoyés au total")
    return total_envoyes
