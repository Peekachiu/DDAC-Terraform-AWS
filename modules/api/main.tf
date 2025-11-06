###############################################
# Private API Layer - Multi-AZ EC2 Instances
# Node.js + Express Setup (Terraform-safe)
###############################################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  target_private_subnets = length(var.private_subnet_ids) > 2 ? slice(var.private_subnet_ids, 0, 2) : var.private_subnet_ids
}

resource "aws_instance" "api" {
  count                       = length(local.target_private_subnets)
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.target_private_subnets[count.index]
  vpc_security_group_ids      = [var.api_sg_id]
  associate_public_ip_address = false
  key_name                    = var.key_name

  # ------------------------------------------
  # User Data Script (literal heredoc to avoid parsing)
  # ------------------------------------------
  user_data = <<EOF
            #!/bin/bash
            apt-get update -y
            apt-get upgrade -y
            apt-get install -y curl git
            
            # Install Node.js (LTS)
            curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
            apt-get install -y nodejs
            
            # Create a simple Express API
            mkdir -p /home/ubuntu/api
            cd /home/ubuntu/api
            
            cat > index.js <<'APP'
            const express = require('express');
            const app = express();
            const PORT = 5000;
            
            app.get('/', (req, res) => {
                res.send('Hello from Private Node.js API!');
            });
            
            app.listen(PORT, '0.0.0.0', () => {
                console.log('API server running on port ' + PORT);
            });
            APP
            
            # Initialize and run the app
            npm init -y
            npm install express
            
            # Run the app in the background
            nohup node /home/ubuntu/api/index.js > /home/ubuntu/api/output.log 2>&1 &
            
            echo "Node.js API server deployed successfully!" > /etc/motd
            EOF

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.vpc_name}-api-${count.index + 1}"
  }
}

###############################################
# Attach API Instances to Internal ALB
###############################################
resource "aws_lb_target_group_attachment" "api_attach" {
  # Only create attachments if an ARN is provided
  count = var.enable_alb_attachment ? length(local.target_private_subnets) : 0

  target_group_arn = var.alb_target_group_arn
  target_id        = aws_instance.api[count.index].id
  port             = 5000
}