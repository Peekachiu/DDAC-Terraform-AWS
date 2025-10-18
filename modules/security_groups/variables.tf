variable "vpc_id" {
  description = "ID of the VPC to associate security groups with"
  type        = string
}

variable "vpc_name" {
  description = "VPC name used for tagging"
  type        = string
}

variable "admin_ip" {
  description = "Public IP address of the admin (in CIDR format)"
  type        = string
}
