
output "instance_id" {
  value = aws_instance.backend.id
}

output "public_ip" {
  value = aws_instance.backend.public_ip
}

output "private_ip" {
  value = aws_instance.backend.private_ip
}

output "ssh_connection" {
  value = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.backend.public_ip}"
}
