"""Journal d'audit des actions sensibles.

Sans trace persistante des validations d'opticien, changements de statut de
commande, traitements de remboursement ou ajustements de stock, il est impossible
de reconstituer ce qui s'est passé après un incident.
"""
import logging

logger = logging.getLogger('audit')


def journaliser(action, utilisateur, **details):
    """Enregistre une action sensible.

    `details` ne doit contenir que des identifiants et des valeurs métier —
    jamais de mot de passe, de jeton ni de contenu de document.
    """
    acteur = getattr(utilisateur, 'username', 'anonyme')
    acteur_id = getattr(utilisateur, 'pk', None)
    contexte = ' '.join(f'{cle}={valeur}' for cle, valeur in sorted(details.items()))
    logger.info('action=%s acteur=%s acteur_id=%s %s', action, acteur, acteur_id, contexte)
