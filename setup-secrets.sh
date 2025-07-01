#!/bin/bash

set -e

log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ $1"
}

GITHUB_USERNAME="xalsie"
NAMESPACE="app"
SECRET_NAME="ghcr-secret"

create_docker_secret() {
    local username=$1
    local token=$2
    
    log_info "Création du secret Docker pour GHCR..."

    kubectl create secret docker-registry ${SECRET_NAME} \
        --docker-server=ghcr.io \
        --docker-username=${username} \
        --docker-password=${token} \
        --docker-email=${username}@users.noreply.github.com \
        --namespace=${NAMESPACE} \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Secret Docker créé avec succès"
}

if ! kubectl cluster-info &> /dev/null; then
    log_error "kubectl n'est pas configuré ou le cluster n'est pas accessible"
    exit 1
fi

if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    log_info "Création du namespace ${NAMESPACE}..."
    kubectl create namespace ${NAMESPACE}
fi

echo
log_info "Pour créer le secret Docker, vous devez fournir votre token GitHub."
echo "📋 Étapes pour créer un token GitHub :"
echo "1. Allez sur https://github.com/settings/tokens"
echo "2. Cliquez sur 'Generate new token (classic)'"
echo "3. Sélectionnez les permissions : read:packages, write:packages"
echo "4. Copiez le token généré"
echo

read -s -p "🔐 Entrez votre token GitHub : " GITHUB_TOKEN
echo

if [ -z "$GITHUB_TOKEN" ]; then
    log_error "Token GitHub requis"
    exit 1
fi

create_docker_secret ${GITHUB_USERNAME} ${GITHUB_TOKEN}

log_info "Vérification du secret..."
kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o yaml | grep -q "kubernetes.io/dockerconfigjson"

log_success "Configuration terminée !"
echo
log_info "Vous pouvez maintenant déployer votre application avec :"
echo "kubectl apply -f kubernetes.yaml"
