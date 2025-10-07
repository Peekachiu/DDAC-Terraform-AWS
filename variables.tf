# Define AWS region as a variable

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-southeast-1"
}

# Define S3 bucket name as a variable

variable "aws_s3_bucket_name" {
  description = "The name of the S3 bucket to store Terraform state"
  type        = string
  default     = "ddac-tf-state-backend"

}
