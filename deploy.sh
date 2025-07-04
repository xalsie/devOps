#!/bin/bash

set -e

PROJECT_NAME="devops"
REGISTRY="ghcr.io"
USERNAME="xalsie"
TAG="latest"

log_info() {
    echo "INFO: $1"
}

log_success() {
    echo "SUCCESS: $1"
}

log_error() {
    echo "ERROR: $1"
}

check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    local missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if ! command -v ansible &> /dev/null; then
        missing_tools+=("ansible")
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        missing_tools+=("ansible-playbook")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Outils manquants: ${missing_tools[*]}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker n'est pas en cours d'exécution"
        exit 1
    fi
    
    if [ ! -f "gitToken.txt" ]; then
        log_error "Le fichier gitToken.txt est manquant. Créez-le avec votre token GitHub."
        exit 1
    fi
    
    log_success "Prérequis OK"
}

deploy_infrastructure() {
    log_info "Déploiement de l'infrastructure avec Terraform"
    cd infrastructure
    log_info "Initialisation de Terraform..."
    terraform init
    log_info "Planification des changements..."
    terraform plan -var-file="terraform.tfvars"
    log_info "Application des changements..."
    terraform apply -var-file="terraform.tfvars" -auto-approve
    cd ..
    log_success "Infrastructure déployée avec succès"
}
generate_outputs() {
    log_info "Génération des outputs Terraform..."
    cd infrastructure
    if [ ! -f "terraform.tfstate" ]; then
        log_error "Aucun état Terraform trouvé. Exécutez 'terraform apply' d'abord."
        exit 1
    fi
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    OUTPUTS_FILE="$SCRIPT_DIR/outputs.json"
    if [ ! -d ".terraform" ]; then
        echo "Terraform n'est pas initialisé. Lancez 'terraform init' d'abord."
        exit 1
    fi
    if [ ! -f "terraform.tfstate" ] || [ ! -s "terraform.tfstate" ]; then
        echo "Aucun state Terraform trouvé. Lancez 'terraform apply' d'abord."
        exit 1
    fi
    terraform output -json > "$OUTPUTS_FILE"
    if [ $? -eq 0 ] && [ -s "$OUTPUTS_FILE" ]; then
        echo "Outputs générés avec succès dans: $OUTPUTS_FILE"
        if command -v jq &> /dev/null; then
            jq -r 'to_entries[] | "- \(.key): \(.value.value)"' "$OUTPUTS_FILE"
        else
            cat "$OUTPUTS_FILE"
        fi
    else
        echo "Erreur lors de la génération des outputs"
        rm -f "$OUTPUTS_FILE"
        exit 1
    fi
    log_success "Outputs générés avec succès dans: outputs.json"
    cd ..
}
}

generate_config_files() {
    log_info "Génération des fichiers de configuration"
    cd infrastructure
    BACKEND_PUBLIC_IP=$(terraform output -raw backend_public_ip)
    BACKEND_PRIVATE_IP=$(terraform output -raw backend_private_ip)
    MONGODB_PUBLIC_IP=$(terraform output -raw mongodb_public_ip)
    MONGODB_PRIVATE_IP=$(terraform output -raw mongodb_private_ip)
    FRONTEND_PUBLIC_IP=$(terraform output -raw frontend_public_ip)
    FRONTEND_PRIVATE_IP=$(terraform output -raw frontend_private_ip)
    if [ -z "$BACKEND_PUBLIC_IP" ] || [ -z "$BACKEND_PRIVATE_IP" ]; then
        log_error "Impossible de récupérer les IPs depuis Terraform"
        exit 1
    fi
    cd ..
    cat > frontend/.env.production << EOF
VITE_BACKEND_URL=http://$BACKEND_PUBLIC_IP:3000
EOF
    cat > ansible/inventory.ini << EOF
[mongodb]
$MONGODB_PUBLIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws-devops.pem

[backend]
$BACKEND_PUBLIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws-devops.pem

[frontend]
$FRONTEND_PUBLIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws-devops.pem

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
mongodb_private_ip=$MONGODB_PRIVATE_IP
backend_private_ip=$BACKEND_PRIVATE_IP
frontend_private_ip=$FRONTEND_PRIVATE_IP
backend_public_ip=$BACKEND_PUBLIC_IP
frontend_public_ip=$FRONTEND_PUBLIC_IP
EOF
    log_success "Fichiers de configuration générés"
    log_info "Frontend .env créé avec BACKEND_URL: http://$BACKEND_PUBLIC_IP"
    log_info "Ansible inventory créé avec l'IP: $BACKEND_PUBLIC_IP"
}

build_and_push_images() {
    log_info "Construction et push des images Docker"
    if [ ! -f "frontend/.env" ]; then
        log_error "Le fichier frontend/.env est manquant. Exécutez d'abord la génération de l'infrastructure."
        exit 1
    fi
    if [ ! -f "ansible/inventory.ini" ]; then
        log_error "Le fichier ansible/inventory.ini est manquant. Exécutez d'abord la génération de l'infrastructure."
        exit 1
    fi
    log_info "Connexion au GitHub Container Registry..."
    GITHUB_TOKEN=$(cat gitToken.txt)
    echo "$GITHUB_TOKEN" | docker login ${REGISTRY} -u ${USERNAME} --password-stdin
    log_info "Construction de l'image backend..."
    if [[ "$(uname -s)" == "Darwin" ]]; then
        docker buildx build --platform linux/amd64,linux/arm64 \
            -t ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/backend:${TAG} \
            --push ./backend --no-cache
        log_success "Image backend construite et poussée"
    fi
    if [[ "$(uname -s)" == "Linux" ]]; then
        docker build -t ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/backend:${TAG} ./backend --no-cache
        docker push ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/backend:${TAG}
    fi
    log_info "Construction de l'image frontend..."
    cd frontend
    if [ -f "package.json" ]; then
        npm install
        npm run build
    fi
    cd ..
    if [[ "$(uname -s)" == "Darwin" ]]; then
        docker buildx build --platform linux/amd64,linux/arm64 \
            -t ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/frontend:${TAG} \
            --push ./frontend --no-cache
        log_success "Image frontend construite et poussée"
    fi
    if [[ "$(uname -s)" == "Linux" ]]; then
        docker build -t ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/frontend:${TAG} ./frontend --no-cache
        docker push ${REGISTRY}/${USERNAME}/${PROJECT_NAME}/frontend:${TAG}
    fi
    log_success "Images Docker construites et poussées avec succès"
}

deploy_with_ansible() {
    log_info "Déploiement avec Ansible"
    sleep 30
    cd infrastructure
    BACKEND_PUBLIC_IP=$(terraform output -raw backend_public_ip)
    FRONTEND_PUBLIC_IP=$(terraform output -raw frontend_public_ip)
    cd ..
    test_ssh_connection() {
        local ip=$1
        local name=$2
        local attempt=0
        local max_attempts=10
        log_info "Test de connexion SSH vers $name ($ip)..."
        while [ $attempt -lt $max_attempts ]; do
            if ssh -i ~/.ssh/aws-devops.pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes ec2-user@$ip "exit" &> /dev/null; then
                log_success "Connexion SSH réussie vers $name ($ip)"
                return 0
            fi
            ((attempt++))
            log_info "Tentative $attempt/$max_attempts échouée pour $name, nouvelle tentative dans 10 secondes..."
            sleep 10
        done
        log_error "Impossible de se connecter à $name ($ip) après $max_attempts tentatives"
        return 1
    }
    {        
        test_ssh_connection "$BACKEND_PUBLIC_IP" "Backend" &
        backend_pid=$!
        test_ssh_connection "$FRONTEND_PUBLIC_IP" "Frontend" &
        frontend_pid=$!
        wait $backend_pid || { log_error "Échec connexion Backend"; exit 1; }
        wait $frontend_pid || { log_error "Échec connexion Frontend"; exit 1; }
    }
    log_success "Toutes les connexions SSH sont opérationnelles"
    cd ansible
    GITHUB_TOKEN=$(cat ../gitToken.txt)
    ansible-playbook -i inventory.ini deploy.yml --extra-vars "github_username=xalsie github_token=$GITHUB_TOKEN"
    cd ..
    rm -f frontend/.env
    rm -f ansible/inventory.ini
    log_success "Déploiement Ansible terminé avec succès"
}

show_deployment_info() {
    log_info "Informations de déploiement"
    cd infrastructure
    BACKEND_PUBLIC_IP=$(terraform output -raw backend_public_ip)
    FRONTEND_PUBLIC_IP=$(terraform output -raw frontend_public_ip)
    cd ..
    echo
    echo "Accès aux services:"
    echo "   Frontend: http://$FRONTEND_PUBLIC_IP:80"
    echo "   Backend:  http://$BACKEND_PUBLIC_IP:3000"
    echo "   Health:   http://$BACKEND_PUBLIC_IP:3000/health"
    echo
    echo "Commandes utiles:"
    echo "   SSH:      ssh ubuntu@$BACKEND_IP"
    echo "   Logs:     ssh ubuntu@$BACKEND_IP 'docker logs backend'"
    echo "   Status:   ssh ubuntu@$BACKEND_IP 'docker ps'"
    echo
    echo "Fichiers générés:"
    echo "   frontend/.env"
    echo "   ansible/inventory.ini"
    echo
}

destroy_all() {
    log_info "Destruction de toutes les ressources"
    cd infrastructure
    terraform destroy -var-file="terraform.tfvars" -auto-approve
    cd ..
    rm -f frontend/.env
    rm -f ansible/inventory.ini
    log_success "Toutes les ressources ont été supprimées"
}

show_help() {
    echo "Usage: $0 {deploy|destroy|info|help}"
    echo
    echo "Commands:"
    echo "  deploy   - Déploie l'infrastructure complète"
    echo "  build    - Déploie l'infrastructure partielle (build seulement)"
    echo "  ansible  - Déploie l'infrastructure avec Ansible (après build)"
    echo "  destroy  - Supprime toutes les ressources"
    echo "  info     - Affiche les informations de déploiement"
    echo "  help     - Affiche cette aide"
    echo
    echo "Prérequis:"
    echo "  terraform, docker, ansible installés"
    echo "  gitToken.txt avec votre token GitHub"
    echo "  Clés SSH configurées (~/.ssh/id_rsa)"
    echo "  AWS CLI configuré"
    echo
}

case "${1:-help}" in
    "deploy")
        echo "DÉPLOIEMENT AUTOMATISÉ COMPLET"
        echo "=================================="
        echo
        check_prerequisites
        deploy_infrastructure
        generate_outputs
        show_deployment_info
        ;;
    "build")
        echo "DÉPLOIEMENT AUTOMATISÉ PARTIEL"
        echo "=================================="
        echo
        check_prerequisites
        build_and_push_images
        deploy_with_ansible
        show_deployment_info
        ;;
    "ansible")
        echo "DÉPLOIEMENT AVEC ANSIBLE"
        echo "=================================="
        echo
        check_prerequisites
        generate_config_files
        deploy_with_ansible
        show_deployment_info
        ;;
    "destroy")
        destroy_all
        ;;
    "info")
        show_deployment_info
        ;;
    "help"|*)
        show_help
        ;;
esac
