import logging
import os
import subprocess
import sys

from django.core.cache import cache
from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from users.permissions import IsAdminSeulement
from utils.audit import journaliser

logger = logging.getLogger(__name__)

MAINTENANCE_KEY = 'site_maintenance'
MAINTENANCE_MSG_KEY = 'site_maintenance_message'


class StatutMaintenance(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response({
            'actif': cache.get(MAINTENANCE_KEY, False),
            'message': cache.get(MAINTENANCE_MSG_KEY, 'Site en maintenance. Revenez bientôt.'),
        })


class ActiverMaintenance(APIView):
    permission_classes = [IsAdminSeulement]

    def post(self, request):
        message = str(request.data.get('message', 'Site en maintenance. Revenez bientôt.'))[:500]
        cache.set(MAINTENANCE_KEY, True, timeout=None)
        cache.set(MAINTENANCE_MSG_KEY, message, timeout=None)
        journaliser('maintenance_activee', request.user)
        return Response({'detail': 'Mode maintenance activé.', 'actif': True})


class DesactiverMaintenance(APIView):
    permission_classes = [IsAdminSeulement]

    def post(self, request):
        cache.delete(MAINTENANCE_KEY)
        cache.delete(MAINTENANCE_MSG_KEY)
        journaliser('maintenance_desactivee', request.user)
        return Response({'detail': 'Mode maintenance désactivé.', 'actif': False})


class LogsSysteme(APIView):
    permission_classes = [IsAdminSeulement]

    def get(self, request):
        log_path = os.environ.get('DJANGO_LOG_PATH', '')
        logs = []
        if log_path and os.path.exists(log_path):
            try:
                with open(log_path, 'r', errors='replace') as f:
                    lines = f.readlines()[-50:]
                for line in reversed(lines):
                    line = line.strip()
                    if not line:
                        continue
                    level = 'info'
                    if 'ERROR' in line:
                        level = 'error'
                    elif 'WARNING' in line:
                        level = 'warning'
                    logs.append({
                        'message': line[:500],
                        'level': level,
                        'timestamp': timezone.now().isoformat(),
                    })
            except OSError:
                logger.exception("Lecture du fichier de log impossible")

        logs.insert(0, {
            'message': f"Système en ligne — {timezone.now().strftime('%d/%m/%Y %H:%M')}",
            'level': 'info',
            'timestamp': timezone.now().isoformat(),
        })
        return Response(logs[:30])


class SauvegardeDB(APIView):
    """Déclenche une sauvegarde chiffrée de la base.

    Le dump contient les empreintes de mots de passe et l'ensemble des données
    personnelles (emails, téléphones, adresses, dates de naissance, numéros de
    police d'assurance). Il ne doit donc jamais être écrit en clair, ni rester
    accessible depuis un répertoire servi par l'application.
    """
    permission_classes = [IsAdminSeulement]

    def post(self, request):
        backup_dir = os.environ.get('BACKUP_DIR', 'backups/')
        recipient = os.environ.get('BACKUP_GPG_RECIPIENT', '')

        if not recipient:
            return Response(
                {
                    'detail': (
                        "Sauvegarde désactivée : définissez BACKUP_GPG_RECIPIENT "
                        "(destinataire GPG) pour que le dump soit chiffré au repos."
                    )
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        os.makedirs(backup_dir, mode=0o700, exist_ok=True)
        timestamp = timezone.now().strftime('%Y%m%d_%H%M%S')
        chemin = os.path.join(backup_dir, f'backup_{timestamp}.json.gpg')

        try:
            # `sys.executable` plutôt que « python » : sur un conteneur, l'appel
            # doit viser l'interpréteur du virtualenv, pas le premier du PATH.
            dump = subprocess.run(
                [sys.executable, 'manage.py', 'dumpdata', '--indent', '2'],
                capture_output=True, timeout=300,
            )
            if dump.returncode != 0:
                logger.error("Échec dumpdata : %s", dump.stderr.decode(errors='replace')[:2000])
                return Response(
                    {'detail': 'Erreur lors de la sauvegarde. Consultez les logs serveur.'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

            chiffrement = subprocess.run(
                ['gpg', '--batch', '--yes', '--trust-model', 'always',
                 '--encrypt', '--recipient', recipient, '--output', chemin],
                input=dump.stdout, capture_output=True, timeout=300,
            )
            if chiffrement.returncode != 0:
                logger.error("Échec du chiffrement GPG : %s",
                             chiffrement.stderr.decode(errors='replace')[:2000])
                return Response(
                    {'detail': 'Erreur lors du chiffrement de la sauvegarde.'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

            os.chmod(chemin, 0o600)
            journaliser('sauvegarde_db', request.user, fichier=os.path.basename(chemin))
            return Response({
                'detail': 'Sauvegarde chiffrée créée.',
                'fichier': os.path.basename(chemin),
            })

        except (OSError, subprocess.SubprocessError):
            # Le message d'exception (chemins internes, stderr de la commande)
            # n'est jamais renvoyé au client.
            logger.exception("Erreur pendant la sauvegarde")
            return Response(
                {'detail': 'Erreur lors de la sauvegarde. Consultez les logs serveur.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
