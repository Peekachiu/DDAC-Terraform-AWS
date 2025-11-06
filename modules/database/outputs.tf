###########################################################
# OUTPUTS — DATABASE MODULE
###########################################################

output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.db_instance.endpoint
}

output "db_port" {
  description = "The port for the RDS instance"
  value       = aws_db_instance.db_instance.port
}

output "db_name" {
  description = "The name of the database"
  value       = aws_db_instance.db_instance.db_name
}