# VPC Configuration for DevSecOps Platform
# Uses existing VPC and subnets for POC deployment

# Data source for existing VPC
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["devopslab"]
  }
}

# Data source for existing public subnet
data "aws_subnet" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  filter {
    name   = "tag:Name"
    values = ["public-subnet-0"]
  }
}

# Data source for existing private subnet (using public subnet for POC)
data "aws_subnet" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  filter {
    name   = "tag:Name"
    values = ["public-subnet-1"]
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
