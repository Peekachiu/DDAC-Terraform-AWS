output "asg_name" {
  description = "Name of the web ASG"
  value       = aws_autoscaling_group.web_asg.name
}

output "web_instance_ids" {
  description = "Instance IDs currently in the ASG"
  value       = aws_autoscaling_group.web_asg.instances[*].instance_id
}

# If you still produce public IPs via the data.aws_instances (above), keep this:
output "web_public_ips" {
  description = "Public IPs of web instances (may be empty during plan)"
  value       = length(data.aws_instances.web_instances) > 0 ? data.aws_instances.web_instances[0].public_ips : []
}

output "web_eip_addresses" {
  description = "EIP addresses assigned (if assign_eip true)"
  value       = var.assign_eip ? [for e in aws_eip.web_eip : e.public_ip] : []
}
