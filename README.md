# DevOps AWS EKS

Projet DevOps avec Terraform (infrastructure modulaire), Ansible et Docker pour déployer une application Svelte (frontend) et une API Node.js (backend) sur AWS.

## Structure du projet

```
├── infrastructure/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── modules/
│       ├── backend/
│       ├── frontend/
│       ├── database/
│       └── networking/
├── frontend/
├── backend/
├── ansible/
├── deploy-full.sh
└── .github/workflows/ci-cd.yml
```

## Coût AWS (Free Tier Eligible)

- EKS Control Plane : Gratuit
- EC2 t3.micro (3 instances) : Gratuit (750h/mois)
- VPC, Subnets, IGW : Gratuit

## Déploiement

### 1. Prérequis
- AWS CLI configuré : `aws configure`
- Clé SSH créée dans AWS EC2 Console (nom à renseigner dans `terraform.tfvars`)
- Token GitHub dans `gitToken.txt`

### 2. Déploiement complet
./deploy-full.sh deploy

### 3. Build & déploiement images + Ansible
./deploy-full.sh build
./deploy-full.sh ansible

### 4. Accès
./deploy-full.sh info

### 5. Nettoyage
./deploy-full.sh destroy

## Infrastructure modulaire

- `modules/networking` : VPC, Subnets, Security Groups
- `modules/database`   : Instance MongoDB
- `modules/backend`    : Instance API Node.js
- `modules/frontend`   : Instance Svelte

Les outputs Terraform sont utilisés pour générer automatiquement :
- `frontend/.env.production` (URL backend)
- `ansible/inventory.ini` (IPs pour Ansible)

## CI/CD

- Validation du code (lint, test, build, sécurité)
- Génération et utilisation des vraies IPs d'outputs Terraform
- Build/push des images Docker sur GitHub Container Registry
- Déploiement Ansible manuel
- Déploiement automatique uniquement sur `main` (sur `develop` : build uniquement)
- Notifications différenciées selon la branche

Secrets GitHub à configurer :
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
