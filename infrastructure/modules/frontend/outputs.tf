output "instance_id" {
  description = "ID of the frontend instance"
  value       = aws_instance.frontend.id
}

output "public_ip" {
  description = "Public IP of the frontend instance"
  value       = aws_instance.frontend.public_ip
}

output "private_ip" {
  description = "Private IP of the frontend instance"
  value       = aws_instance.frontend.private_ip
}

output "ssh_connection" {
  description = "SSH connection command for frontend instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.frontend.public_ip}"
}
