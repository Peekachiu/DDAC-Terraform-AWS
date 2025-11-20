############################################################
# Root-Level Terraform Configuration for DDAC Project
############################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

############################################################
# VPC Module
############################################################
module "vpc" {
  source = "./modules/vpc"

  vpc_name   = var.vpc_name
  cidr_block = var.vpc_cidr
  azs        = var.availability_zones

  public_subnets = [
    { name = "public-subnet-1", cidr = "10.0.1.0/24", az = "ap-southeast-1a" },
    { name = "public-subnet-2", cidr = "10.0.2.0/24", az = "ap-southeast-1b" }
  ]

  private_subnets = [
    { name = "private-subnet-1a", cidr = "10.0.11.0/24", az = "ap-southeast-1a" },
    { name = "private-subnet-2a", cidr = "10.0.12.0/24", az = "ap-southeast-1a" },
    { name = "private-subnet-1b", cidr = "10.0.21.0/24", az = "ap-southeast-1b" },
    { name = "private-subnet-2b", cidr = "10.0.22.0/24", az = "ap-southeast-1b" }
  ]

  # NAT Gateway Configuration
  enable_nat_gateway = true # Enables NAT Gateway for private subnet internet access
  enable_multi_nat   = true # Set to true if you want one NAT per AZ (for HA)
  single_nat_index   = 0    # 0 = Use the first public subnet for NAT Gateway
}

############################################################
# Dynamic Admin IP Detection (with Auto-Refresh Capability)
############################################################

# Fetch your current public IP
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

# Trim whitespace and format it as a CIDR block
locals {
  detected_admin_ip = "${chomp(data.http.my_ip.response_body)}/32"

  # Allow manual override (e.g., when running from a CI/CD pipeline or VPN)
  admin_ip = var.admin_ip_override != "" ? var.admin_ip_override : local.detected_admin_ip
}

############################################################
# Security Groups Module
############################################################
module "security_groups" {
  source   = "./modules/security_groups"
  vpc_id   = module.vpc.vpc_id
  vpc_name = var.vpc_name
  admin_ip = local.admin_ip
}

############################################################
# Bastion Host Module
############################################################
module "bastion" {
  source            = "./modules/bastion"
  vpc_name          = var.vpc_name
  instance_type     = "t3.micro"
  key_name          = "ddac-bastion-key"
  bastion_sg_id     = module.security_groups.bastion_sg_id
  public_subnet_ids = module.vpc.public_subnet_ids
  enable_multi_az   = true
  assign_eip        = false
  root_volume_size  = 8
}

############################################################
# Web Server Module (Public Subnets, Multi-AZ)
############################################################
module "web_server" {
  source                    = "./modules/web_server"
  vpc_name                  = var.vpc_name
  project_name              = var.project_name
  public_subnet_ids         = module.vpc.public_subnet_ids
  web_sg_id                 = module.security_groups.web_sg_id
  key_name                  = var.key_name
  instance_type             = "t3.micro"
  root_volume_size          = 8
  iam_instance_profile_name = module.iam_web.instance_profile_name

  # Auto Scaling settings — ensure one instance per AZ
  asg_min_size         = 2
  asg_desired_capacity = 2
  asg_max_size         = 2

  # Pass the ALB target group ARN so the ASG registers instances
  alb_target_group_arn = module.alb.alb_target_group_arn

  # Pass in the new INTERNAL ALB's DNS name
  api_alb_dns_name = module.internal_alb.alb_dns_name

  # Ensure the Auto Scaling service-linked role exists before ASG creation
  depends_on = [module.iam_web]
}


############################################################
# Application Load Balancer Module
############################################################
module "alb" {
  source       = "./modules/alb"
  project_name = var.project_name
  vpc_name     = var.vpc_name
  vpc_id       = module.vpc.vpc_id
  lb_sg_id     = module.security_groups.lb_sg_id
  subnet_ids   = module.vpc.public_subnet_ids
  name_prefix  = "web"
  is_internal  = false
  target_port  = 80
  enable_https = false
}

############################################################
# Application Load Balancer Module (INTERNAL - API)
############################################################
module "internal_alb" {
  source       = "./modules/alb"
  project_name = var.project_name
  vpc_name     = var.vpc_name
  vpc_id       = module.vpc.vpc_id

  # Use the new API LB security group you created
  lb_sg_id = module.security_groups.api_lb_sg_id

  # Use private subnets
  subnet_ids = [
    module.vpc.private_subnets_map["private-subnet-1a"],
    module.vpc.private_subnets_map["private-subnet-1b"]
  ]

  # Use the new variables
  name_prefix = "api"
  is_internal = true
  target_port = 5000
}

############################################################
# API Layer Module
############################################################
module "api" {
  source        = "./modules/api"
  vpc_name      = var.vpc_name
  instance_type = "t3.micro"
  key_name      = var.key_name
  api_sg_id     = module.security_groups.api_sg_id

  # Pass in ALL private subnets for the ASG to use
  private_subnet_ids = module.vpc.private_subnet_ids

  root_volume_size = 8

  # Pass the target group ARN directly to the ASG
  alb_target_group_arn = module.internal_alb.alb_target_group_arn

  # Add the new ASG variables
  asg_min_size         = 2
  asg_desired_capacity = 2
  asg_max_size         = 2

  iam_instance_profile_name = module.iam_api.instance_profile_name
  db_secret_name            = aws_secretsmanager_secret.db_secret.name

  depends_on = [module.security_groups, module.database]
}

############################################################
# IAM Module
############################################################
module "iam_web" {
  source                = "./modules/iam"
  manage_role           = true
  role_name             = "DDAC-web-ec2-role"
  instance_profile_name = "DDAC-web-ec2-profile"
  project               = var.project_name
}

############################################################
# Database Layer Module (RDS - MSSQL)
############################################################
module "database" {
  source       = "./modules/database"
  project_name = var.project_name
  vpc_name     = var.vpc_name

  # Pass in the private subnets from the VPC module
  private_subnet_ids = module.vpc.private_subnet_ids

  # Pass in the DB security group ID
  db_sg_id = module.security_groups.db_sg_id

  # Pass in the new credentials
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  # Ensure the security group exists before creating the DB
  depends_on = [module.security_groups]
}

############################################################
# Create Secret for Database Credentials
############################################################
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${var.vpc_name}-db-credentials-final"
  description = "Database credentials for the API layer"

  # Force delete allows terraform destroy to work immediately
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = module.database.db_address
    port     = module.database.db_port
    dbname   = var.db_name
    engine   = "mysql"
  })
}

############################################################
# Create IAM Role for API Layer
############################################################
module "iam_api" {
  source                = "./modules/iam"
  manage_role           = true
  role_name             = "${var.project_name}-api-role"
  instance_profile_name = "${var.project_name}-api-profile"
  project               = var.project_name
}

############################################################
# Grant API Role Permission to Read Secret
############################################################
resource "aws_iam_role_policy" "api_secrets_policy" {
  name = "${var.project_name}-api-secrets-policy"
  role = module.iam_api.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db_secret.arn
      }
    ]
  })
}

############################################################
# WAF Module (Global - us-east-1)
############################################################
module "waf" {
  source       = "./modules/waf"
  project_name = var.project_name

  providers = {
    aws = aws.us-east-1
  }
}

############################################################
# CloudFront Module
############################################################
module "cloudfront" {
  source              = "./modules/cloudfront"
  project_name        = var.project_name
  alb_dns_name        = module.alb.alb_dns_name
  waf_web_acl_arn     = module.waf.web_acl_arn
  domain_name         = var.domain_name
  acm_certificate_arn = module.acm.acm_certificate_arn
}

############################################################
# Route 53 & Certificate
############################################################

# 1. Get the Hosted Zone (Assumes you created it in console when buying domain)
data "aws_route53_zone" "main" {
  name = var.domain_name
}

# 2. Create Certificate
module "acm" {
  source      = "./modules/acm"
  domain_name = var.domain_name
  zone_id     = data.aws_route53_zone.main.zone_id

  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}

# 3. Create DNS Record for CloudFront (The "A" Record)
resource "aws_route53_record" "cdn_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # This is the fixed Zone ID for CloudFront
    evaluate_target_health = false
  }
}

############################################################
# Cloudwatch Monitoring & Alerting
############################################################

module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name = var.project_name
  alert_email  = var.alert_email

  # Passing data from other modules
  web_asg_name     = module.web_server.asg_name
  api_instance_ids = module.api.instance_ids
  alb_arn_suffix   = module.alb.alb_arn_suffix
  db_instance_id   = module.db.db_instance_identifier
}