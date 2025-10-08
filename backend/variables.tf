# Define Region name as a variable
variable "region" {
  description = "The AWS region to deploy the backend infrastructure."
  type        = string
  default     = "ap-southeast-1"
}

# Define S3 bucket name as a variable
variable "bucket_name" {
  description = "The name of the S3 bucket to store Terraform state."
  type        = string
  default     = "ddac-tf-state-backend"
  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.bucket_name))
    error_message = "Bucket name must be between 3 and 63 characters, and can only contain lowercase letters, numbers, dots, and hyphens."
  }
}

# Define DynamoDB table name as a variable
variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table for Terraform state locking."
  type        = string
  default     = "terraform-state-locking"
}
