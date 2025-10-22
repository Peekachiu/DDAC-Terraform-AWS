###############################################
# Fetch Latest Ubuntu 22.04 LTS AMI (ap-southeast-1)
###############################################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################################
# Multi-AZ Web Server Deployment
###############################################
resource "aws_instance" "web" {
  count                  = length(var.public_subnet_ids)
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[count.index]
  key_name               = var.key_name
  vpc_security_group_ids = [var.web_sg_id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl enable nginx
              systemctl start nginx

              # Custom welcome page
              echo "<h1>DDAC Web Server - $(hostname)</h1>" > /var/www/html/index.html
              EOF

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.vpc_name}-web-${count.index + 1}"
    Project = var.project_name
  }
}

###############################################
# Elastic IPs (Optional for public access)
###############################################
resource "aws_eip" "web_eip" {
  count    = var.assign_eip ? length(aws_instance.web) : 0
  instance = aws_instance.web[count.index].id
  domain   = "vpc"

  tags = {
    Name = "${var.vpc_name}-web-eip-${count.index + 1}"
  }
}