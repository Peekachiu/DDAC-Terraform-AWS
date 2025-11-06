###############################################
# Variables for Private API Module
###############################################

variable "vpc_name" {
  description = "VPC name for tagging purposes"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where API instances are deployed"
  type        = list(string)
}

variable "api_sg_id" {
  description = "Security group ID for API instances"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name (for bastion access)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for API layer"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root volume size for API instances (GB)"
  type        = number
  default     = 8
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB Target Group to attach API instances to"
  type        = string
  default     = ""
}