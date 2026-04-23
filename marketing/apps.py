import sys
from django.apps import AppConfig


class MarketingConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'marketing'

    def ready(self):
        # Ne pas démarrer le scheduler lors des commandes manage.py (migrate, etc.)
        # ni lors des tests, ni dans le processus de rechargement automatique de runserver
        if 'runserver' not in sys.argv and 'gunicorn' not in sys.argv[0:1]:
            return
        if sys.argv[1:2] == ['runserver'] and '--noreload' not in sys.argv:
            import os
            if os.environ.get('RUN_MAIN') != 'true':
                return

        self._demarrer_scheduler()

    def _demarrer_scheduler(self):
        try:
            from apscheduler.schedulers.background import BackgroundScheduler
            from apscheduler.triggers.cron import CronTrigger
            from django_apscheduler.jobstores import DjangoJobStore
            from django_apscheduler.models import DjangoJobExecution
            from .tasks import envoyer_anniversaires_auto
            import logging

            logger = logging.getLogger(__name__)

            scheduler = BackgroundScheduler(timezone='Africa/Abidjan')
            scheduler.add_jobstore(DjangoJobStore(), 'default')

            # Nettoyer les anciennes exécutions (> 7 jours)
            scheduler.add_job(
                DjangoJobExecution.objects.delete_old_job_executions,
                trigger=CronTrigger(day_of_week='mon', hour=2, minute=0),
                id='purge_job_executions',
                max_instances=1,
                replace_existing=True,
                args=[7],
            )

            # Tâche principale : anniversaires — tourne chaque heure et vérifie les configs
            scheduler.add_job(
                envoyer_anniversaires_auto,
                trigger=CronTrigger(hour='*', minute=0),
                id='anniversaires_auto',
                max_instances=1,
                replace_existing=True,
            )

            scheduler.start()
            logger.info("[Scheduler] Démarré — vérification anniversaires chaque heure.")

        except Exception as e:
            import logging
            logging.getLogger(__name__).error(f"[Scheduler] Erreur au démarrage : {e}")
