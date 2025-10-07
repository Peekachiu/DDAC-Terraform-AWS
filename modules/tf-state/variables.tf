variable "bucket_name" {
  description = "The name of the S3 bucket to store Terraform state"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.bucket_name))
    error_message = "Bucket name must be between 3 and 63 characters, and can only contain lowercase letters, numbers, dots, and hyphens."
  }
}

# Define DynamoDB table name as a variable

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-state-locking"
}