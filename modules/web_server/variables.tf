###########################################################
# VARIABLES — WEB SERVER MODULE (ASG + Launch Template)
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
  description = "SSH key pair name for web servers (optional — set empty to use SSM only)"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "EBS root volume size (GB)"
  type        = number
  default     = 8
}

variable "assign_eip" {
  description = "Whether to assign Elastic IPs to web instances (discouraged for ASG-managed fleets)"
  type        = bool
  default     = false
}

variable "ami_id" {
  description = "Optional AMI ID to use for instances. If empty, module will fetch latest Ubuntu 22.04 AMI (fallback). For deterministic plans, pass a fixed AMI ID."
  type        = string
  default     = ""
}

variable "asg_min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 1
}

variable "alb_target_group_arn" {
  description = "Optional ALB target group ARN. If provided, ASG will register targets to this TG."
  type        = string
  default     = ""
}

variable "user_data" {
  description = "Optional user data script to provision instances (base64 is not required). If empty, a minimal nginx bootstrap will be used."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
