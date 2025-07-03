output "instance_id" {
  description = "ID of the backend instance"
  value       = aws_instance.backend.id
}

output "public_ip" {
  description = "Public IP of the backend instance"
  value       = aws_instance.backend.public_ip
}

output "private_ip" {
  description = "Private IP of the backend instance"
  value       = aws_instance.backend.private_ip
}

output "ssh_connection" {
  description = "SSH connection command for backend instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.backend.public_ip}"
}
