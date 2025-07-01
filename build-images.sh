#!/bin/bash

set -e

REGISTRY="ghcr.io"
USERNAME="xalsie"
PROJECT_NAME="devops"
TAG="latest"

log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ $1"
}

build_and_push() {
    local service=$1
    local context_dir=$2
    
    log_info "Construction de l'image $service..."
    
    docker buildx build --platform linux/amd64,linux/arm64 \
        -t ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/${service}:${TAG} \
        --push ${context_dir}
    
    log_success "Image $service construite et poussée"
}

if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker n'est pas en cours d'exécution"
    exit 1
fi

log_info "Connexion au GitHub Container Registry..."
echo "Veuillez vous connecter avec votre token GitHub (pas votre mot de passe) :"
docker login ${REGISTRY} -u ${USERNAME}

build_and_push "backend" "./backend"
build_and_push "frontend" "./frontend"

log_success "Toutes les images ont été construites et poussées avec succès !"

echo
log_info "Images disponibles :"
echo "- ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/backend:${TAG}"
echo "- ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/frontend:${TAG}"
