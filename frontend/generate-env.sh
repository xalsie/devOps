#!/bin/bash

# Script pour générer le fichier .env à partir des outputs Terraform

echo "Génération du fichier .env à partir des outputs Terraform..."

# Aller dans le dossier infrastructure pour exécuter terraform output
cd ../infrastructure

# Récupérer l'IP du backend public depuis les outputs Terraform
BACKEND_IP=$(terraform output -raw backend_public_ip)

if [ -z "$BACKEND_IP" ]; then
  echo "Erreur: Impossible de récupérer l'IP du backend depuis les outputs Terraform"
  exit 1
fi

echo "IP du backend public récupérée: $BACKEND_IP"

# Créer le fichier .env dans le dossier frontend
cd ../frontend
cat > .env << EOF
# Configuration générée automatiquement depuis les outputs Terraform
VITE_BACKEND_URL=http://$BACKEND_IP:3000
EOF

echo "Fichier .env généré avec succès:"
cat .env
