#!/bin/bash

set -e

# Configuration
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

# Vérifier Docker et buildx
setup_buildx() {
    log_info "Configuration de Docker Buildx pour multi-architecture..."
    
    # Créer un builder multi-architecture si nécessaire
    if ! docker buildx ls | grep -q multiarch; then
        docker buildx create --name multiarch --use
        log_success "Builder multiarch créé"
    else
        docker buildx use multiarch
        log_info "Utilisation du builder multiarch existant"
    fi
    
    # Bootstrap le builder
    docker buildx inspect --bootstrap
}

# Construire et pousser pour AMD64 (architecture des nœuds EKS)
build_and_push_multiarch() {
    local service=$1
    local context_dir=$2
    
    log_info "Construction multi-architecture de l'image $service..."
    
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --tag ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/${service}:${TAG} \
        --push \
        ${context_dir}
    
    log_success "Image $service construite et poussée (multi-arch)"
}

# Vérifications préalables
if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker n'est pas en cours d'exécution"
    exit 1
fi

# Configuration buildx
setup_buildx

# Se connecter au registry
log_info "Connexion au GitHub Container Registry..."
echo "Entrez votre token GitHub :"
docker login ${REGISTRY} -u ${USERNAME}

# Construire les images
log_info "Construction des images avec support multi-architecture..."
build_and_push_multiarch "backend" "./backend"
build_and_push_multiarch "frontend" "./frontend"

log_success "Toutes les images ont été construites et poussées avec succès !"

echo
log_info "Images disponibles (multi-arch) :"
echo "- ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/backend:${TAG}"
echo "- ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/frontend:${TAG}"
