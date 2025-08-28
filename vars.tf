variable "aws_profile" {
  description = "AWS CLI profile name to use for authentication"
  type        = string
  default     = "raj-private"
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-west-1"
}

variable "ami-name" {
  description = "AMI ID for EC2 instance (Amazon Linux 2 in eu-west-1)"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "instance-size" {
  description = "Instance type for application servers"
  type        = string
  default     = "t2.micro"
}

variable "private-subnet1" {
  description = "Private subnet ID for EC2 deployment"
  type        = string
  default     = "subnet-0123456789abcdef0"  # Update with actual Ireland subnet
}

variable "key-pair" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = "raj-private-ireland"
}

variable "security-group" {
  description = "Security Group ID for EC2 instance"
  type        = string
  default     = "sg-0123456789abcdef0"  # Update with actual Ireland security group
}

variable "ec2-role" {
  description = "IAM instance profile for EC2"
  type        = string
  default     = ""  # Will use the created IAM instance profile
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_name" {
  description = "Name of the existing VPC to deploy into"
  type        = string
  default     = "devopslab"
}

# Note: Using existing VPC and subnets from devopslab VPC
# Default VPC name is 'devopslab' - override if different

# DevSecOps Server Variables
variable "devsecops_instance_type" {
  description = "Instance type for DevSecOps server"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "github_webhook_secret" {
  description = "Secret for GitHub webhook validation"
  type        = string
  default     = "your-webhook-secret-here"
  sensitive   = true
}

variable "sonarqube_admin_password" {
  description = "Admin password for SonarQube"
  type        = string
  default     = "admin123!"
  sensitive   = true
}

