# =========================================================
# Root Outputs — From the VPC Module
# =========================================================

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "nat_eip_addresses" {
  description = "Elastic IP addresses attached to the NAT Gateways"
  value       = module.vpc.nat_eip_addresses
}

# =========================================================
# Root Outputs — From the Security Groups Module
# =========================================================

output "public_sg_id" {
  description = "ID of the public security group"
  value       = module.security_groups.public_sg_id
}

output "private_sg_id" {
  description = "ID of the private security group"
  value       = module.security_groups.private_sg_id
}

output "db_sg_id" {
  description = "ID of the database security group"
  value       = module.security_groups.db_sg_id
}

output "bastion_sg_id" {
  description = "ID of the bastion host security group"
  value       = module.security_groups.bastion_sg_id
}

# =========================================================
# Admin IP Detection Output
# =========================================================
output "admin_ip" {
  description = "The detected or manually overridden admin IP used in security groups"
  value       = local.admin_ip
}

# =========================================================
# Bastion Host Outputs
# =========================================================
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_public_dns" {
  description = "Public DNS of the bastion host"
  value       = module.bastion.bastion_public_dns
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host"
  value       = module.bastion.bastion_instance_id
}

output "bastion_public_ips" {
  description = "List of public IPs for all bastion hosts"
  value       = aws_eip.bastion_eip[*].public_ip
}

