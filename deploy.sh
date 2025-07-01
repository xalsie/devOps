#!/bin/bash

set -e

PROJECT_NAME="devops-minimal"
AWS_REGION="eu-west-3"

log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ $1"
}

check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform n'est pas installé"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl n'est pas installé"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI n'est pas installé"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI n'est pas configuré"
        exit 1
    fi
    
    log_success "Prérequis OK"
}

deploy_infrastructure() {
    log_info "Déploiement de l'infrastructure..."
    
    cd infrastructure
    
    terraform init
    terraform plan -var-file="terraform.tfvars"
    terraform apply -var-file="terraform.tfvars" -auto-approve
    
    log_success "Infrastructure déployée"
    cd ..
}

configure_kubectl() {
    log_info "Configuration de kubectl..."
    
    aws eks update-kubeconfig --region $AWS_REGION --name ${PROJECT_NAME}-cluster
    
    log_success "kubectl configuré"
}

setup_secrets() {
    log_info "Configuration des secrets pour les images privées..."
    
    if ! kubectl get secret ghcr-secret -n app &> /dev/null; then
        log_info "Le secret ghcr-secret n'existe pas. Exécution du script de configuration..."
        ./setup-secrets.sh
    else
        log_info "Secret ghcr-secret déjà configuré"
    fi
}

deploy_app() {
    log_info "Déploiement de l'application..."
    
    kubectl apply -f kubernetes.yaml
    
    log_info "Attente du déploiement..."
    kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n app
    kubectl wait --for=condition=available --timeout=300s deployment/backend -n app
    kubectl wait --for=condition=available --timeout=300s deployment/frontend -n app
    
    log_success "Application déployée"
}

show_info() {
    echo
    log_info "🌐 Accès à l'application:"
    
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    
    echo "Frontend: http://$NODE_IP:30000"
    echo "Backend:  http://$NODE_IP:30001"
    echo
    log_info "📋 Commandes utiles:"
    echo "kubectl get pods -n app"
    echo "kubectl logs -f deployment/backend -n app"
    echo "kubectl logs -f deployment/frontend -n app"
}

destroy_all() {
    log_info "Destruction des ressources..."
    
    kubectl delete -f kubernetes.yaml --ignore-not-found=true
    
    cd infrastructure
    terraform destroy -var-file="terraform.tfvars" -auto-approve
    cd ..
    
    log_success "Ressources supprimées"
}

case "${1:-help}" in
    "deploy")
        check_prerequisites
        deploy_infrastructure
        configure_kubectl
        setup_secrets
        deploy_app
        show_info
        ;;
    "destroy")
        destroy_all
        ;;
    "info")
        show_info
        ;;
    *)
        echo "Usage: $0 {deploy|destroy|info}"
        echo
        echo "deploy  - Déploie l'infrastructure et l'application"
        echo "destroy - Supprime tout"
        echo "info    - Affiche les infos d'accès"
        ;;
esac
