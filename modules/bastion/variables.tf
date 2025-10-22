###############################################
# Variables for Bastion Host Module
###############################################

variable "vpc_name" {
  description = "VPC name for tagging purposes"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet where the bastion will reside"
  type        = string
}

variable "bastion_sg_id" {
  description = "ID of the bastion security group"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name for accessing the bastion host"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size (GB) for the Bastion host"
  type        = number
  default     = 8
}

variable "assign_eip" {
  description = "Whether to assign an Elastic IP to the bastion host"
  type        = bool
  default     = true
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for multi-AZ bastion deployment"
  type        = list(string)
}

variable "enable_multi_az" {
  description = "Whether to deploy bastion hosts in multiple AZs"
  type        = bool
  default     = false
}


