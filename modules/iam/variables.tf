variable "role_name" { 
    type = string 
    default = "terraform-admin-ec2-role"
}

variable "instance_profile_name" { 
    type = string 
    default = "terraform-admin-ec2-instance-profile"
}

variable "s3_buckets" { 
    type = list(string) 
    default = [] 
}