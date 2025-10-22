# =====================================
# SECURITY GROUP CONFIGURATION MODULE
# =====================================

############################################################
# 1. Public Web Security Group
# ----------------------------------------------------------
# - Allows HTTP/HTTPS from internet
# - Allows SSH only from admin IP (optional)
############################################################
resource "aws_security_group" "public_sg" {
  name        = "${var.vpc_name}-public-sg"
  description = "Allow HTTP, HTTPS, and restricted SSH"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-public-sg"
  }
}

############################################################
# 2. API (Private) Security Group
# ----------------------------------------------------------
# - Allows traffic from web servers only (port 5000 by default)
# - Denies all other inbound traffic
############################################################
resource "aws_security_group" "api_sg" {
  name        = "${var.vpc_name}-api-sg"
  description = "Allow API access from web servers only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow API traffic from Web SG"
    from_port       = var.api_port
    to_port         = var.api_port
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-api-sg"
  }
}

############################################################
# 3. Database Security Group
# ----------------------------------------------------------
# - Allows database access from API SG only (port 3306 default)
############################################################
resource "aws_security_group" "db_sg" {
  name        = "${var.vpc_name}-db-sg"
  description = "Allow DB access from API SG only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow database connection from API SG"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.api_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-db-sg"
  }
}

############################################################
# 4. Bastion Host Security Group
# ----------------------------------------------------------
# - Allows SSH from admin IP
# - Can reach all private instances (for maintenance)
############################################################
resource "aws_security_group" "bastion_sg" {
  name        = "${var.vpc_name}-bastion-sg"
  description = "Allow SSH from admin IP only"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-bastion-sg"
  }
}
