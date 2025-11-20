# =========================================================
# Root Variables for Terraform Configuration
# =========================================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "DDAC-VPC"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "admin_ip_override" {
  description = "Optional manual override for admin IP (e.g. 115.135.24.27/32). Leave empty to auto-detect."
  type        = string
  default     = "115.135.24.27/32" # Manually set to a specific IP for testing
}

variable "project_name" {
  description = "Project name tag for all resources"
  type        = string
  default     = "DDAC"
}

variable "key_name" {
  description = "AWS key pair name to use for SSH access"
  type        = string
  default     = "ddac-bastion-key"
}

# =========================================================
# Database Variables
# =========================================================

variable "db_name" {
  description = "The name of the database to create (e.g., DDAC)"
  type        = string
  default     = "DDAC_DB"
}

variable "db_username" {
  description = "Master username for the RDS database"
  type        = string
  default     = "ddacadmin"
}

variable "db_password" {
  description = "Master password for the RDS database (must meet complexity requirements)"
  type        = string
  default     = "ddac1234!"
  sensitive   = true
}

# =========================================================
# Route 53 Variables
# =========================================================
variable "domain_name" {
  description = "Your custom domain name (e.g., ddac-test.click)"
  type        = string
}

# =========================================================
# Cloudwatch Variables
# =========================================================
variable "alert_email" {
  description = "Your email address for CloudWatch alerts"
  type        = string
}