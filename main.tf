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
  region = "ap-southeast-1"
}

# The "tf-state" module is commented out to avoid re-creating the S3 bucket and DynamoDB table if they already exist.
# It only needs to be run once to set up the backend infrastructure.

module "tf-state" {
  source      = "./modules/tf-state"
  bucket_name = "ddac-tf-state-backend"
}

# --- VPC Module ---
module "vpc" {
  source = "./modules/vpc"

  vpc_name   = "ddac-VPC-01"
  cidr_block = "10.0.0.0/16"
  azs        = ["ap-southeast-1a", "ap-southeast-1b"]

  public_subnets = [
    { name = "public-subnet-1", cidr = "10.0.1.0/24", az = "ap-southeast-1a" },
    { name = "public-subnet-2", cidr = "10.0.2.0/24", az = "ap-southeast-1b" }
  ]

  private_subnets = [
    { name = "private-subnet-1a", cidr = "10.0.11.0/24", az = "ap-southeast-1a" },
    { name = "private-subnet-2a", cidr = "10.0.12.0/24", az = "ap-southeast-1a" },
    { name = "private-subnet-1b", cidr = "10.0.21.0/24", az = "ap-southeast-1b" },
    { name = "private-subnet-2b", cidr = "10.0.22.0/24", az = "ap-southeast-1b" }
  ]
}