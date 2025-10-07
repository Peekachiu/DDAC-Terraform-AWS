terraform {
  required_version = ">=1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "tf-state" {
  source      = "./modules/tf-state"
  bucket_name = var.aws_s3_bucket_name
}