terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.26.0"
    }
  }
}

# Using local backend for POC - no remote state needed
# terraform {
#   backend "s3" {
#     bucket         = "demo-tf-state-rsood"
#     key            = "terraform.tfstate"
#     region         = "us-west-2"  # Original bucket region
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }
