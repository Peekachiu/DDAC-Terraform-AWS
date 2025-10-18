# =====================================
# SECURITY GROUP CONFIGURATION MODULE
# =====================================

# -------------------------------
# 1. Public Security Group
# -------------------------------
resource "aws_security_group" "public_sg" {
  name        = "${var.vpc_name}-public-sg"
  description = "Allow HTTP, HTTPS, and SSH from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
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

# -------------------------------
# 2. Private Security Group
# -------------------------------
resource "aws_security_group" "private_sg" {
  name        = "${var.vpc_name}-private-sg"
  description = "Allow inbound from public SG and outbound to anywhere"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow inbound from public SG"
    from_port       = 0
    to_port         = 65535
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
    Name = "${var.vpc_name}-private-sg"
  }
}

# -------------------------------
# 3. Database Security Group
# -------------------------------
resource "aws_security_group" "db_sg" {
  name        = "${var.vpc_name}-db-sg"
  description = "Allow DB access from private SG only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow MySQL/Aurora from private SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.private_sg.id]
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

# -------------------------------
# 4. Bastion Host Security Group
# -------------------------------
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-bastion-sg"
  }
}
