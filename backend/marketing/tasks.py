"""Tâche planifiée : envoi automatique des messages d'anniversaire."""
import logging
import re

from django.contrib.auth import get_user_model
from django.utils import timezone

logger = logging.getLogger(__name__)
User = get_user_model()

# Seuls ces jetons sont substituables dans un gabarit de message.
JETONS_AUTORISES = ('prenom', 'nom', 'boutique')

_MOTIF_JETON = re.compile(r'\{([^{}]*)\}')


def rendre_message(gabarit, **valeurs):
    """Substitue les jetons d'un gabarit fourni par un opticien.

    `str.format()` était utilisé directement sur ce gabarit. Deux problèmes :

    - un jeton inconnu levait une `KeyError` qui remontait hors de la boucle et
      interrompait les envois de TOUS les autres opticiens ;
    - la mini-syntaxe de `format` autorise la traversée d'attributs
      (`{prenom.__class__...}`), ce qui en fait un vecteur de divulgation dès que
      l'on passe un objet un peu riche en argument.

    On n'accepte donc qu'une liste blanche de jetons, remplacés littéralement.
    """
    inconnus = [
        jeton for jeton in _MOTIF_JETON.findall(gabarit or '')
        if jeton not in JETONS_AUTORISES
    ]
    if inconnus:
        raise ValueError(
            f"Jeton(s) non autorisé(s) : {', '.join(sorted(set(inconnus)))}. "
            f"Jetons disponibles : {', '.join(JETONS_AUTORISES)}."
        )

    message = gabarit or ''
    for jeton in JETONS_AUTORISES:
        message = message.replace('{' + jeton + '}', str(valeurs.get(jeton, '')))
    return message


def envoyer_anniversaires_auto(opticien=None):
    """Envoie les messages d'anniversaire du jour.

    `opticien` restreint le traitement à un seul compte (déclenchement manuel) ;
    sans argument, la tâche planifiée traite toutes les configurations actives.
    """
    from sms_otp.sms_service import envoyer_sms

    from .models import ConfigAutoAnniversaire, HistoriqueSMS

    today = timezone.now().date()
    configs = ConfigAutoAnniversaire.objects.filter(actif=True).select_related('opticien')
    if opticien is not None:
        configs = configs.filter(opticien=opticien)

    total_envoyes = 0

    for config in configs:
        # Chaque opticien est traité isolément : une configuration invalide ne
        # doit jamais interrompre le traitement des autres.
        try:
            total_envoyes += _traiter_config(config, today, envoyer_sms, HistoriqueSMS)
        except Exception:
            logger.exception(
                "[Anniversaire AUTO] Échec pour l'opticien %s", config.opticien_id
            )

    logger.info("[Anniversaire AUTO] %s SMS envoyés au total", total_envoyes)
    return total_envoyes


def _traiter_config(config, today, envoyer_sms, HistoriqueSMS):
    opticien = config.opticien
    envoyes = 0

    clients_anniv = User.objects.filter(
        role='client',
        is_active=True,
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

        try:
            message = rendre_message(
                config.message_template,
                prenom=client.first_name or client.username,
                nom=client.last_name or '',
                boutique=getattr(getattr(opticien, 'boutique', None), 'nom', 'OptiLunette'),
            )
        except ValueError:
            logger.error(
                "[Anniversaire AUTO] Gabarit invalide pour l'opticien %s — envoi ignoré.",
                opticien.pk,
            )
            return envoyes

        sent = envoyer_sms(client.telephone, message) if client.telephone else False

        HistoriqueSMS.objects.create(
            destinataire=client,
            telephone=client.telephone or '',
            message=message,
            type_message='anniversaire',
            envoye=sent,
            envoye_par=opticien,
        )

        if sent:
            envoyes += 1
            logger.info(
                "[Anniversaire AUTO] SMS envoyé au client %s par l'opticien %s",
                client.pk, opticien.pk,
            )

    return envoyes
