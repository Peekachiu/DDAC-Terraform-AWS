variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of Availability Zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet configurations"
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  description = "List of private subnet configurations"
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
}
