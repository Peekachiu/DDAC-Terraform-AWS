###########################################################
# VARIABLES — WEB SERVER MODULE
###########################################################

variable "vpc_name" {
  description = "VPC name for tagging"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "DDAC"
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for multi-AZ deployment"
  type        = list(string)
}

variable "web_sg_id" {
  description = "Security group ID for web servers"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name for web servers"
  type        = string
}

variable "root_volume_size" {
  description = "EBS root volume size (GB)"
  type        = number
  default     = 8
}

variable "assign_eip" {
  description = "Whether to assign Elastic IPs to web instances"
  type        = bool
  default     = true
}