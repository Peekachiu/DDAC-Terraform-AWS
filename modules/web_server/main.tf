###########################################################
# Web Server Module — Launch Template + Auto Scaling Group
# - SSM instance profile for Session Manager
# - Optional ALB target group integration
# - Optional EIP assignment (not recommended)
###########################################################

# Fallback AMI (Canonical Ubuntu 22.04) if no ami_id provided
data "aws_ami" "ubuntu" {
  count       = var.ami_id == "" ? 1 : 0
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

locals {
  ami_resolved = var.ami_id != "" ? var.ami_id : (length(data.aws_ami.ubuntu) > 0 ? data.aws_ami.ubuntu[0].id : "")
  common_tags  = merge({
    Project = var.project_name
    VPC     = var.vpc_name
  }, var.tags)
  userdata_script = var.user_data != "" ? var.user_data : <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>DDAC Web Server - $(hostname)</h1>" > /var/www/html/index.html
  EOF
}

# IAM role & instance profile for SSM (recommended instead of SSH-only)
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-web-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-web-instance-profile"
  role = aws_iam_role.ec2_role.name
  tags = local.common_tags
}

# Launch Template with user_data and instance profile
resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.project_name}-web-lt-"
  image_id      = local.ami_resolved
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # key_name is optional; ASG + SSM allows you to omit SSH key
  key_name = var.key_name != "" ? var.key_name : null

  network_interfaces {
    security_groups             = [var.web_sg_id]
    associate_public_ip_address = true
  }

  user_data = base64encode(local.userdata_script)

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
    tags          = merge(local.common_tags, { Name = "${var.project_name}-web" })
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name                = "${var.project_name}-web-asg"
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  vpc_zone_identifier = var.public_subnet_ids

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  health_check_type         = var.alb_target_group_arn != "" ? "ELB" : "EC2"
  health_check_grace_period = 300

  target_group_arns = var.alb_target_group_arn != "" ? [var.alb_target_group_arn] : null

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Optional: EIPs for ASG instances (discouraged for autoscaling fleets)
resource "aws_eip" "web_eip" {
  count = var.assign_eip ? length(aws_autoscaling_group.web_asg.instances) : 0

  instance = aws_autoscaling_group.web_asg.instances[count.index].instance_id
  domain   = "vpc"

  tags = local.common_tags
}


# (Optional) If you need instance-level provisioning beyond user_data,
# consider integrating SSM Run Command / Fleet Manager or a configuration management tool.
