provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# Only DevSecOps server resources needed - removed unnecessary app security group
