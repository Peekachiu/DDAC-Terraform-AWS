variable "project_name" {}

variable "web_asg_name" {}

variable "api_instance_ids" { 
    type = list(string) 
}

variable "alb_arn_suffix" {}

variable "db_instance_id" {}

variable "alert_email" {
  description = "Email address to send alerts to"
  type        = string
}