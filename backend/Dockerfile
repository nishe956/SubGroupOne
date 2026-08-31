FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    tesseract-ocr \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Utilisateur non privilégié : sans directive USER, gunicorn tournait en root,
# ce qui transforme toute exécution de code arbitraire dans l'application en
# compromission complète du conteneur.
RUN useradd --create-home --uid 10001 app

COPY --chown=app:app requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=app:app . .

RUN chmod +x entrypoint.sh \
    && mkdir -p /app/staticfiles /app/media \
    && chown -R app:app /app/staticfiles /app/media

USER app

EXPOSE 8000

# La sonde vise /healthz/, court-circuité en tête de MIDDLEWARE. L'ancienne
# cible /api/maintenance/statut/ échouait en production pour trois raisons
# cumulées : hôte 127.0.0.1 absent d'ALLOWED_HOSTS, redirection HTTPS forcée, et
# limite DRF de 100 requêtes anonymes par jour atteinte en cinquante minutes.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD python -c "import os,urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:%s/healthz/' % os.environ.get('PORT','8000'), timeout=4).status == 200 else 1)"

CMD ["./entrypoint.sh"]
