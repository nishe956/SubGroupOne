#!/bin/sh
set -e

# Les migrations ne sont PAS jouées ici : avec plusieurs instances, deux
# migrations concurrentes entrent en conflit, et une migration destructrice
# s'appliquerait automatiquement sans validation humaine. Elles doivent être
# lancées explicitement lors du déploiement :
#     python manage.py migrate --noinput
# Mettre RUN_MIGRATIONS=1 pour retrouver l'ancien comportement (mono-instance).
if [ "${RUN_MIGRATIONS:-0}" = "1" ]; then
    python manage.py migrate --noinput
fi

python manage.py collectstatic --noinput

# Render, Koyeb et Fly imposent le port d'écoute par la variable PORT : un port
# codé en dur laissait la plateforme sonder un port fermé et conclure à un
# démarrage échoué. Le repli sur 8000 conserve le comportement en local.
PORT="${PORT:-8000}"

# `--preload` : les workers partagent le code chargé une seule fois, ce qui
# évite notamment de démarrer un ordonnanceur APScheduler par worker.
#
# Un seul worker par défaut : sur une instance gratuite de 512 Mo, deux workers
# Django plus le décodage d'images de l'essai virtuel dépassent la limite et le
# conteneur est tué (OOM). Passer GUNICORN_WORKERS à 2 ou plus dès que
# l'instance dispose de mémoire.
exec gunicorn config.wsgi:application \
    --bind "0.0.0.0:${PORT}" \
    --workers "${GUNICORN_WORKERS:-1}" \
    --preload \
    --timeout 120 \
    --max-requests 1000 \
    --max-requests-jitter 100 \
    --access-logfile - \
    --error-logfile -
