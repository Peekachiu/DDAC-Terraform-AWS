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

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    security_groups             = [var.api_sg_id]
    associate_public_ip_address = false # IMPORTANT: Keep this false for private
  }

  # Updated User Data
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get upgrade -y
    # Install tools
    apt-get install -y unzip curl git jq

    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install  # <--- FIXED: Added this line

    # Install Node.js (LTS)
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    # Create a simple Express API
    mkdir -p /home/ubuntu/api
    cd /home/ubuntu/api
    
    # -------------------------------------------------------
    # 1. FETCH SECRETS
    # -------------------------------------------------------
    # Fetch the secret JSON using the AWS CLI
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${var.db_secret_name} --query SecretString --output text --region ap-southeast-1)

    # Parse values using jq and export them as Bash variables
    export DB_HOST=$(echo $SECRET_JSON | jq -r .host)
    export DB_USER=$(echo $SECRET_JSON | jq -r .username)
    export DB_PASS=$(echo $SECRET_JSON | jq -r .password)
    export DB_NAME=$(echo $SECRET_JSON | jq -r .dbname)
    export DB_PORT=$(echo $SECRET_JSON | jq -r .port)
    
    # -------------------------------------------------------
    # 2. CREATE NODE.JS APP
    # -------------------------------------------------------
    # FIXED: Changed <<'APP' to <<APP (no quotes) so variables expand
    cat > index.js <<APP
    const express = require('express');
    const mysql = require('mysql2');
    const app = express();
    const PORT = 5000;

    // Database Connection Config
    // FIXED: Used $VAR syntax instead of ${VAR} to avoid Terraform errors
    const dbConfig = {
      host: "$DB_HOST",
      user: "$DB_USER",
      password: "$DB_PASS", 
      database: "$DB_NAME",
      port: $DB_PORT
    };

    // Create a connection pool
    const pool = mysql.createPool(dbConfig);

    app.get('/', (req, res) => {
        res.send('<h1>DDAC API Layer</h1><p>Status: Running</p><a href="/db-test">Test Database Connection</a>');
    });

    // Test DB Connection Endpoint
    app.get('/db-test', (req, res) => {
        pool.query('SELECT 1 + 1 AS solution', (error, results) => {
            if (error) {
                res.status(500).send('Database Connection Failed: ' + error.message);
                return;
            }
            res.send('Database Connection Successful! Test Query Result: ' + results[0].solution);
        });
    });

    app.listen(PORT, '0.0.0.0', () => {
        console.log('API server running on port ' + PORT);
    });
    APP
    
    # Initialize and install dependencies
    npm init -y
    npm install express mysql2
    
    # Run the app
    nohup node index.js > output.log 2>&1 &
    
    echo "API deployed with DB connection!" > /etc/motd
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
      Name = "${var.vpc_name}-api"
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