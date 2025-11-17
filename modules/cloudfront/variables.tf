variable "project_name" {
  type = string
}

variable "alb_dns_name" {
  description = "The DNS name of the Public ALB (Origin)"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL to attach"
  type        = string
}