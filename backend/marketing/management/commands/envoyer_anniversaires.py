"""Envoi des messages d'anniversaire — point d'entrée pour un ordonnanceur externe.

L'ordonnanceur APScheduler intégré (marketing/apps.py) suppose un process qui
tourne en permanence. Sur un hébergement gratuit, l'instance est mise en veille
après quelques minutes d'inactivité : la tâche horaire ne partirait jamais.
Cette commande permet de confier la planification au cron de la plateforme, à
GitHub Actions ou à n'importe quel service de cron externe.

    python manage.py envoyer_anniversaires

La tâche est idempotente sur la journée : `envoyer_anniversaires_auto` tient un
historique par client et par jour, donc deux exécutions rapprochées n'envoient
pas deux SMS (et n'en facturent pas deux).
"""
from django.core.management.base import BaseCommand

from marketing.tasks import envoyer_anniversaires_auto


class Command(BaseCommand):
    help = "Envoie les SMS d'anniversaire du jour pour toutes les configurations actives."

    def handle(self, *args, **options):
        envoyes = envoyer_anniversaires_auto()
        self.stdout.write(self.style.SUCCESS(
            f"Tâche anniversaires terminée — {envoyes} SMS envoyé(s)."
        ))
