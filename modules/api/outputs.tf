###############################################
# Outputs for Private API Instances
###############################################

output "api_instance_ids" {
  description = "IDs of the API EC2 instances"
  value       = [for i in aws_instance.api : i.id]
}

output "api_private_ips" {
  description = "Private IPs of API EC2 instances"
  value       = [for i in aws_instance.api : i.private_ip]
}

output "api_private_dns" {
  description = "Private DNS names of API EC2 instances"
  value       = [for i in aws_instance.api : i.private_dns]
}
