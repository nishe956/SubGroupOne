"""Gestionnaire d'exceptions DRF.

Objectif : ne jamais renvoyer au client le détail d'une exception non prévue
(chemins internes, requêtes SQL, URL d'API tierces, versions de bibliothèques).
Le détail part dans les logs avec un identifiant de corrélation que l'utilisateur
peut communiquer au support.
"""
import logging
import uuid

from rest_framework.response import Response
from rest_framework.views import exception_handler
from rest_framework import status

logger = logging.getLogger(__name__)


def gestionnaire_exceptions(exc, context):
    reponse = exception_handler(exc, context)
    if reponse is not None:
        # Exception métier attendue (validation, permission, 404...) : le message
        # est volontairement destiné à l'utilisateur, on le laisse passer.
        return reponse

    # Exception non gérée : 500. On journalise tout, on ne divulgue rien.
    reference = uuid.uuid4().hex[:12]
    vue = context.get('view').__class__.__name__ if context.get('view') else 'inconnue'
    logger.exception("Erreur non gérée [%s] dans %s", reference, vue)

    return Response(
        {
            'detail': "Une erreur interne est survenue. Contactez le support en "
                      "indiquant la référence ci-dessous.",
            'reference': reference,
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )
