# terraform {
#   backend "s3" {
#     bucket         = "ddac-tf-state-backend"
#     key            = "terraform.tfstate"
#     region         = "ap-southeast-1"
#     dynamodb_table = "terraform-state-locking"
#     encrypt        = true
#   }
# }
