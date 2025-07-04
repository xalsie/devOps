terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  aws_region         = var.aws_region
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
}

module "database" {
  source = "./modules/database"

  project_name      = var.project_name
  instance_type     = "t3.micro"
  ssh_key_name      = var.ssh_key_name
  security_group_id = module.networking.database_security_group_id
  subnet_id         = module.networking.public_subnet_id
}

module "backend" {
  source = "./modules/backend"

  project_name      = var.project_name
  instance_type     = "t3.micro"
  ssh_key_name      = var.ssh_key_name
  security_group_id = module.networking.web_security_group_id
  subnet_id         = module.networking.public_subnet_id
}

module "frontend" {
  source = "./modules/frontend"

  project_name      = var.project_name
  instance_type     = "t3.micro"
  ssh_key_name      = var.ssh_key_name
  security_group_id = module.networking.web_security_group_id
  subnet_id         = module.networking.public_subnet_id
}
