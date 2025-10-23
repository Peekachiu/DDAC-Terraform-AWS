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
  default     = "219.93.16.130/32" # Manually set to a specific IP for testing
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
