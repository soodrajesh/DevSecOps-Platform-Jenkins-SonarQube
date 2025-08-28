/**
 * Main Terraform Configuration for DevSecOps Platform
 * 
 * This module deploys a complete DevSecOps environment on AWS with Jenkins, SonarQube,
 * and security scanning tools pre-configured in a single EC2 instance.
 * 
 * Features:
 * - Automated provisioning of DevSecOps tools
 * - Secure network configuration with configurable CIDR blocks
 * - IAM roles with least privilege access
 * - Automated setup scripts for tool configuration
 * 
 * Prerequisites:
 * - AWS CLI configured with appropriate credentials
 * - Terraform 1.6.6 or later
 * - SSH key pair in AWS region
 */

# Configure AWS provider with region and profile
provider "aws" {
  region  = var.region
  profile = var.aws_profile
  
  # Default tags for all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "DevSecOps-Pipeline"
      ManagedBy   = "Terraform"
      Repository  = "ci-cd-project-3"
    }
  }
}

# Data sources for existing VPC and subnets
data "aws_vpc" "existing" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.existing.id
  tags = {
    Name = "${var.vpc_name}-public-${var.region}a"
  }
}

# Local values for consistent tagging
locals {
  common_tags = {
    Environment = var.environment
    Project     = "DevSecOps-Pipeline"
    ManagedBy   = "Terraform"
    Name        = "devsecops-${var.environment}"
  }
}
