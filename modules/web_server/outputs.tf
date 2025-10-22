###########################################################
# OUTPUTS — WEB SERVER MODULE
###########################################################

output "web_instance_ids" {
  description = "IDs of all web server instances"
  value       = [for w in aws_instance.web : w.id]
}

output "web_public_ips" {
  description = "Public IPs of web servers"
  value       = var.assign_eip ? [for e in aws_eip.web_eip : e.public_ip] : [for w in aws_instance.web : w.public_ip]
}

output "web_public_dns" {
  description = "Public DNS names of web servers"
  value       = [for w in aws_instance.web : w.public_dns]
}