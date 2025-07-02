output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "mongodb_public_ip" {
  description = "Public IP of the MongoDB instance"
  value       = aws_instance.mongodb.public_ip
}

output "backend_public_ip" {
  description = "Public IP of the Backend instance"
  value       = aws_instance.backend.public_ip
}

output "frontend_public_ip" {
  description = "Public IP of the Frontend instance"
  value       = aws_instance.frontend.public_ip
}

output "mongodb_private_ip" {
  description = "Private IP of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "backend_private_ip" {
  description = "Private IP of the Backend instance"
  value       = aws_instance.backend.private_ip
}

output "frontend_private_ip" {
  description = "Private IP of the Frontend instance"
  value       = aws_instance.frontend.private_ip
}

output "ssh_connection_mongodb" {
  description = "SSH connection command for MongoDB instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.mongodb.public_ip}"
}

output "ssh_connection_backend" {
  description = "SSH connection command for Backend instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.backend.public_ip}"
}

output "ssh_connection_frontend" {
  description = "SSH connection command for Frontend instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.frontend.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}

output "backend_security_groups" {
  description = "Security groups attached to backend instance"
  value       = aws_instance.backend.vpc_security_group_ids
}
