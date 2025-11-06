###############################################
# Application Load Balancer (Public)
###############################################

# Create the ALB
resource "aws_lb" "app_lb" {
  name               = "${var.vpc_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.lb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name    = "${var.vpc_name}-alb"
    Project = var.project_name
  }
}

###############################################
# Target Group for Web Servers
###############################################
resource "aws_lb_target_group" "web_tg" {
  name     = "${var.vpc_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.vpc_name}-tg"
  }
}

###############################################
# ALB Listener (HTTP - Port 80)
###############################################
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

###############################################
# Optional Future HTTPS Listener (Port 443)
###############################################
resource "aws_lb_listener" "https_listener" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
