output "instance_id" {
  description = "ID of the MongoDB instance"
  value       = aws_instance.mongodb.id
}

output "public_ip" {
  description = "Public IP of the MongoDB instance"
  value       = aws_instance.mongodb.public_ip
}

output "private_ip" {
  description = "Private IP of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "ssh_connection" {
  description = "SSH connection command for MongoDB instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.mongodb.public_ip}"
}
