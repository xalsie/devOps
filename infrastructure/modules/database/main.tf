# Récupérer l'AMI Amazon Linux 2023 la plus récente
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instance pour MongoDB
resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    
    # Installer Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    mkdir -p /data/mongodb
    chown ec2-user:ec2-user /data/mongodb
  EOF

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true

    tags = {
      Name = "${var.project_name}-mongodb-root"
    }
  }

  tags = {
    Name    = "${var.project_name}-mongodb"
    Role    = "database"
    Service = "mongodb"
  }
}
