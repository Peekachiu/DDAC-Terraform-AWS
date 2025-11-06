###########################################################
# OUTPUTS — WEB SERVER MODULE (ASG)
###########################################################

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.web_asg.name
}

output "web_instance_ids" {
  description = "Instance IDs currently in the ASG"
  # may be empty until instances exist
  value       = data.aws_autoscaling_group.web_asg.instances[*].instance_id
}

output "web_eip_addresses" {
  description = "EIP addresses assigned (if assign_eip true)"
  value       = var.assign_eip ? [for e in aws_eip.web_eip : e.public_ip] : []
}
