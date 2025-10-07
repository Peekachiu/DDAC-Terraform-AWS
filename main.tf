terraform {
  backend "s3" {
    bucket         = "ddac-tf-state-backend"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

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

module "tf-state" {
  source      = "./modules/tf-state"
  bucket_name = "ddac-tf-state-backend"
}