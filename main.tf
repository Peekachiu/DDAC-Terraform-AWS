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


############################################################
# VPC Module
############################################################
module "vpc" {
  source = "./modules/vpc"

  vpc_name   = "ddac-VPC-01"
  cidr_block = "10.0.0.0/16"
  azs        = ["ap-southeast-1a", "ap-southeast-1b"]

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
  enable_nat_gateway = true          # Enables NAT Gateway for private subnet internet access
  enable_multi_nat   = true          # Set to true if you want one NAT per AZ (for HA)
  single_nat_index   = 0             # 0 = Use the first public subnet for NAT Gateway
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
  source            = "./modules/web_server"
  vpc_name          = var.vpc_name
  project_name      = var.project_name
  public_subnet_ids = module.vpc.public_subnet_ids
  web_sg_id         = module.security_groups.web_sg_id
  key_name          = var.key_name
  instance_type     = "t3.micro"
  root_volume_size  = 8
  assign_eip        = true
}

############################################################
# Application Load Balancer Module
############################################################
module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  vpc_name          = var.vpc_name
  vpc_id            = module.vpc.vpc_id
  lb_sg_id          = module.security_groups.lb_sg_id
  public_subnet_ids = module.vpc.public_subnet_ids
  web_instance_ids  = module.web_server.web_instance_ids

  enable_https      = false    # 🔒 set to true later when you add ACM certificate
}

############################################################
# API Layer Module (Node.js Express - Multi-AZ)
############################################################

# Find private subnets by AZ for deterministic mapping
data "aws_subnets" "private_1a" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet-1a"]
  }
}

data "aws_subnets" "private_1b" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet-1b"]
  }
}

module "api" {
  source = "./modules/api"

  vpc_name = var.vpc_name
  instance_type = "t3.micro"
  key_name = var.key_name
  api_sg_id = module.security_groups.api_sg_id

  # ✅ Assign explicitly by AZ
  private_subnet_ids = [
    data.aws_subnets.private_1a.ids[0],
    data.aws_subnets.private_1b.ids[0]
  ]

  root_volume_size = 8
}
