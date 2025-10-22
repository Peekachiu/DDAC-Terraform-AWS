###############################################
# Fetch Latest Ubuntu 22.04 LTS AMI (ap-southeast-1)
###############################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical (official Ubuntu)
}

###############################################
# Bastion Host Module - EC2 Instance in Public Subnet
###############################################

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name      = var.key_name

  vpc_security_group_ids = [var.bastion_sg_id]

  associate_public_ip_address = true

  # ------------------------------------------
  # User Data Script (runs on instance startup)
  # ------------------------------------------
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y unzip curl git awscli openssh-server

              # Optional: install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Ensure SSH service is active
              systemctl enable ssh
              systemctl start ssh

              # Add banner for clarity
              echo "Welcome to DDAC Bastion Host (Ubuntu)" > /etc/motd
              EOF

  # ✅ Root volume configuration
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }  

  tags = {
    Name = "${var.vpc_name}-bastion-host"
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion_eip" {
  count    = var.assign_eip ? 1 : 0
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "${var.vpc_name}-bastion-eip"
  }
}

