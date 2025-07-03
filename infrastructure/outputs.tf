output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "mongodb_public_ip" {
  description = "Public IP of the MongoDB instance"
  value       = module.database.public_ip
}

output "backend_public_ip" {
  description = "Public IP of the Backend instance"
  value       = module.backend.public_ip
}

output "frontend_public_ip" {
  description = "Public IP of the Frontend instance"
  value       = module.frontend.public_ip
}

output "mongodb_private_ip" {
  description = "Private IP of the MongoDB instance"
  value       = module.database.private_ip
}

output "backend_private_ip" {
  description = "Private IP of the Backend instance"
  value       = module.backend.private_ip
}

output "frontend_private_ip" {
  description = "Private IP of the Frontend instance"
  value       = module.frontend.private_ip
}

output "ssh_connection_mongodb" {
  description = "SSH connection command for MongoDB instance"
  value       = module.database.ssh_connection
}

output "ssh_connection_backend" {
  description = "SSH connection command for Backend instance"
  value       = module.backend.ssh_connection
}

output "ssh_connection_frontend" {
  description = "SSH connection command for Frontend instance"
  value       = module.frontend.ssh_connection
}

# Outputs additionnels pour la gestion modulaire
output "networking_info" {
  description = "Informations sur le réseau"
  value = {
    vpc_id                     = module.networking.vpc_id
    public_subnet_id          = module.networking.public_subnet_id
    web_security_group_id     = module.networking.web_security_group_id
    database_security_group_id = module.networking.database_security_group_id
  }
}

output "instances_info" {
  description = "Informations sur les instances"
  value = {
    database = {
      instance_id = module.database.instance_id
      public_ip   = module.database.public_ip
      private_ip  = module.database.private_ip
    }
    backend = {
      instance_id = module.backend.instance_id
      public_ip   = module.backend.public_ip
      private_ip  = module.backend.private_ip
    }
    frontend = {
      instance_id = module.frontend.instance_id
      public_ip   = module.frontend.public_ip
      private_ip  = module.frontend.private_ip
    }
  }
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}

output "backend_security_groups" {
  description = "Security groups attached to backend instance"
  value       = aws_instance.backend.vpc_security_group_ids
}
