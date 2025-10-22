###############################################
# Outputs for Bastion Host
###############################################

output "bastion_instance_id" {
  description = "ID of the bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_eip.bastion_eip.public_ip
}

output "bastion_public_dns" {
  description = "Public DNS of the bastion host"
  value       = aws_instance.bastion.public_dns
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host (if assigned)"
  value       = var.assign_eip ? aws_eip.bastion_eip[0].public_ip : aws_instance.bastion.public_ip
}
