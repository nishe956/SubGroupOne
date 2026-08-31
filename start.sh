#!/bin/bash

echo "Arrêt des ports en cours..."
fuser -k 8000/tcp 2>/dev/null
fuser -k 8001/tcp 2>/dev/null
fuser -k 5173/tcp 2>/dev/null

echo "Démarrage du backend..."
cd /home/eddy/Lunette-project/backend
mkdir -p certs
if [ ! -f certs/localhost.pem ] || [ ! -f certs/localhost-key.pem ]; then
  echo "Génération des certificats backend (mkcert)..."
  mkcert -cert-file certs/localhost.pem -key-file certs/localhost-key.pem localhost 127.0.0.1 ::1
fi
source .venv/bin/activate
python3 manage.py runserver 127.0.0.1:8001 &
python3 dev_https_proxy.py &

echo "Démarrage du frontend..."
cd /home/eddy/Lunette-project/frontend
npm run dev
