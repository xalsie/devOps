# Version Minimaliste - DevOps AWS EKS

Version ultra-simplifiée pour déployer frontend et backend sur AWS avec un coût minimal.

## Structure du projet

```
├── infrastructure/
│   ├── main.tf           # Infrastructure EKS minimaliste
│   ├── variables.tf      # Variables Terraform
│   ├── outputs.tf        # Outputs Terraform
│   └── terraform.tfvars  # Configuration
├── frontend/             # Application Svelte
├── backend/              # API Node.js
├── kubernetes.yaml       # Déploiement Kubernetes
├── deploy.sh             # Script de déploiement
└── .github/workflows/deploy.yml # Pipeline GitHub Actions
```

## Coût AWS (Free Tier Eligible)

- **EKS Control Plane**: Gratuit
- **EC2 t3.micro (2 instances)**: Gratuit (750h/mois)
- **VPC, Subnets, IGW**: Gratuit

**Coût estimé**: 0€/mois avec le Free Tier AWS ✅

## Déploiement

### 1. Prérequis
```bash
# AWS CLI configuré
aws configure

# Créer une clé SSH dans AWS EC2 Console
# Mettre le nom dans infrastructure/terraform.tfvars
```

### 2. Déploiement
```bash
./deploy.sh deploy
```

### 3. Accès
```bash
./deploy.sh info
```

### 4. Nettoyage
```bash
./deploy.sh destroy
```

## Architecture

```
┌─────────────────────────────────┐
│            AWS VPC              │
│         (10.0.0.0/16)          │
│                                 │
│  ┌─────────────────────────┐   │
│  │      EKS Cluster        │   │
│  │   (Control Plane FREE)  │   │
│  │                         │   │
│  │  ┌─────────────────┐   │   │
│  │  │   t3.micro      │   │   │
│  │  │   Nodes         │   │   │
│  │  │                 │   │   │
│  │  │ Frontend :30000 │   │   │
│  │  │ Backend  :30001 │   │   │
│  │  │ MongoDB  :27017 │   │   │
│  │  └─────────────────┘   │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

## CI/CD

Push sur `main` → Build automatique → Déploiement EKS

Configuration GitHub Secrets :
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
