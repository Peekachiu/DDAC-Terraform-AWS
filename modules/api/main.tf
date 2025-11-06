###############################################
# Fetch Latest Ubuntu 22.04 LTS AMI
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
# API Server Launch Template
###############################################
resource "aws_launch_template" "api_lt" {
  name_prefix   = "${var.vpc_name}-api-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    security_groups             = [var.api_sg_id]
    associate_public_ip_address = false # IMPORTANT: Keep this false for private
  }

  # User data to install Node.js API
  user_data = base64encode(<<-EOF
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
  )

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.vpc_name}-api" // All instances will get this name
    }
  }
}

###############################################
# API Server Auto Scaling Group
###############################################
resource "aws_autoscaling_group" "api_asg" {
  name                = "${var.vpc_name}-api-asg"
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  
  # Deploy across all private subnets provided
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.api_lt.id
    version = "$Latest"
  }

  # Use the ALB health check
  health_check_type         = "ELB"
  health_check_grace_period = 300 // Wait 5 mins for instance to be healthy

  # Auto-attach to the internal ALB target group
  target_group_arns = var.alb_target_group_arn != "" ? [var.alb_target_group_arn] : []

  tag {
    key                 = "Name"
    value               = "${var.vpc_name}-api"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}