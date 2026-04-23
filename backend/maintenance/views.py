from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions
from django.core.cache import cache
from django.utils import timezone
from users.permissions import IsOpticienOuAdmin, IsAdminSeulement
import subprocess, os, logging

logger = logging.getLogger(__name__)

MAINTENANCE_KEY    = 'site_maintenance'
MAINTENANCE_MSG_KEY = 'site_maintenance_message'


class StatutMaintenance(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        actif   = cache.get(MAINTENANCE_KEY, False)
        message = cache.get(MAINTENANCE_MSG_KEY, 'Site en maintenance. Revenez bientôt.')
        return Response({'actif': actif, 'message': message})


class ActiverMaintenance(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request):
        message = request.data.get('message', 'Site en maintenance. Revenez bientôt.')
        cache.set(MAINTENANCE_KEY, True, timeout=None)
        cache.set(MAINTENANCE_MSG_KEY, message, timeout=None)
        logger.info(f"Maintenance activée par {request.user.username}")
        return Response({'detail': 'Mode maintenance activé.', 'actif': True})


class DesactiverMaintenance(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request):
        cache.delete(MAINTENANCE_KEY)
        cache.delete(MAINTENANCE_MSG_KEY)
        logger.info(f"Maintenance désactivée par {request.user.username}")
        return Response({'detail': 'Mode maintenance désactivé.', 'actif': False})


class LogsSysteme(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        # Read Django log file if it exists
        log_path = os.environ.get('DJANGO_LOG_PATH', 'logs/django.log')
        logs = []
        if os.path.exists(log_path):
            try:
                with open(log_path, 'r') as f:
                    lines = f.readlines()[-50:]  # Last 50 lines
                    for line in reversed(lines):
                        line = line.strip()
                        if line:
                            level = 'info'
                            if 'ERROR' in line:   level = 'error'
                            elif 'WARNING' in line: level = 'warning'
                            logs.append({'message': line, 'level': level, 'timestamp': timezone.now().isoformat()})
            except Exception:
                pass

        # Add system events
        logs.insert(0, {
            'message': f"Système en ligne — {timezone.now().strftime('%d/%m/%Y %H:%M')}",
            'level': 'info',
            'timestamp': timezone.now().isoformat(),
        })

        return Response(logs[:30])


class SauvegardeDB(APIView):
    permission_classes = [IsAdminSeulement]

    def post(self, request):
        backup_dir = os.environ.get('BACKUP_DIR', 'backups/')
        os.makedirs(backup_dir, exist_ok=True)
        timestamp = timezone.now().strftime('%Y%m%d_%H%M%S')
        filename  = f"{backup_dir}backup_{timestamp}.json"

        try:
            result = subprocess.run(
                ['python', 'manage.py', 'dumpdata', '--indent', '2', '-o', filename],
                capture_output=True, text=True, timeout=120,
            )
            if result.returncode == 0:
                logger.info(f"Backup créé: {filename} par {request.user.username}")
                return Response({'detail': f'Sauvegarde créée: {filename}', 'fichier': filename})
            else:
                return Response({'detail': 'Erreur lors de la sauvegarde.', 'error': result.stderr}, status=500)
        except Exception as e:
            logger.error(f"Erreur backup: {e}")
            return Response({'detail': f'Erreur: {str(e)}'}, status=500)
