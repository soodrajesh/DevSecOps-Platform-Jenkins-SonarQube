# Terraform Variables Example
# Copy this file to terraform.tfvars and update with your actual values

# AWS Configuration
aws_profile = "raj-private"
region      = "eu-west-1"

# EC2 Configuration
ami-name      = "ami-07cb1aa266ef8b45d" # Latest Amazon Linux 2 AMI
instance-size = "t3.micro"
key-pair      = "opsworx-ie" # Available key pair

# Network Configuration (using existing devopslab VPC resources)
# Note: VPC and subnets are now referenced via data sources
# No need to specify VPC/subnet IDs as they're discovered automatically

# Legacy variables (kept for compatibility with example instance)
security-group = "sg-0123456789abcdef0"            # Update if needed for example instance
ec2-role       = "demo-EC2InstanceProfile-ireland" # Update if needed

# DevSecOps Server Configuration
devsecops_instance_type  = "t3.micro" # Sufficient for Jenkins + SonarQube
github_webhook_secret    = "your-webhook-secret-here"
sonarqube_admin_password = "your-secure-password-here"
