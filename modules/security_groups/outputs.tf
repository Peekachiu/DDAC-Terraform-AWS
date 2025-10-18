output "public_sg_id" {
  description = "ID of the public security group"
  value       = aws_security_group.public_sg.id
}

output "private_sg_id" {
  description = "ID of the private security group"
  value       = aws_security_group.private_sg.id
}

output "db_sg_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db_sg.id
}

output "bastion_sg_id" {
  description = "ID of the bastion host security group"
  value       = aws_security_group.bastion_sg.id
}
