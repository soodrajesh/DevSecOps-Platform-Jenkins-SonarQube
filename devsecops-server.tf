/**
 * DevSecOps Server - EC2 Instance Configuration
 * 
 * This module creates an EC2 instance pre-configured with a complete DevSecOps toolchain:
 * - Jenkins CI/CD Server
 * - SonarQube for static code analysis
 * - Security scanning tools (OWASP ZAP, Bandit, Checkov, etc.)
 * - Docker and Docker Compose for containerization
 * - AWS CLI and Terraform for infrastructure as code
 * 
 * Security Features:
 * - Configurable CIDR blocks for all ingress rules
 * - IAM instance profile with least privilege permissions
 * - Encrypted EBS root volume
 * - IMDSv2 required for instance metadata access
 * - Security group with minimum required ports open
 * 
 * Note: Default security group rules are permissive for demo purposes.
 *       Restrict access in production using the allowed_*_cidr variables.
 */

resource "aws_security_group" "devsecops_sg" {
  name_prefix = "devsecops-server-${terraform.workspace}"
  description = "Security group for DevSecOps server"
  vpc_id      = data.aws_vpc.existing.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # WARNING: For demo purposes, SSH is open to the world. Restrict to your IP for production!
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH access (restrict in production)"
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    # WARNING: Jenkins UI is open to the world for demo. Restrict to trusted IPs in production!
    cidr_blocks = [var.allowed_jenkins_cidr]
    description = "Jenkins web interface (restrict in production)"
  }

  # SonarQube
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    # WARNING: SonarQube UI is open to the world for demo. Restrict to trusted IPs in production!
    cidr_blocks = [var.allowed_sonarqube_cidr]
    description = "SonarQube web interface (restrict in production)"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # WARNING: HTTPS is open to the world for demo. Restrict to trusted IPs in production!
    cidr_blocks = [var.allowed_https_cidr]
    description = "HTTPS access (restrict in production)"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # WARNING: HTTP is open to the world for demo. Restrict to trusted IPs in production!
    cidr_blocks = [var.allowed_http_cidr]
    description = "HTTP access (restrict in production)"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "devsecops-server-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = "DevSecOps-Pipeline"
    ManagedBy   = "Terraform"
  }
}

# IAM role for DevSecOps server
resource "aws_iam_role" "devsecops_role" {
  name = "devsecops-server-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "devsecops-server-role-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = "DevSecOps-Pipeline"
    ManagedBy   = "Terraform"
  }
}

# IAM policy for DevSecOps operations
resource "aws_iam_role_policy" "devsecops_policy" {
  name = "devsecops-server-policy-${terraform.workspace}"
  role = aws_iam_role.devsecops_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # EC2 instance management for Jenkins agents and pipeline automation
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress"
        ]
        Resource = "*"

        # S3 for artifact storage
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "*"

        # IAM PassRole for Jenkins and automation (least privilege)
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::*:role/devsecops-*"

        # Lambda, CloudFormation, and other pipeline automation (read-only)
        Action = [
          "lambda:ListFunctions",
          "cloudformation:DescribeStacks"
        ]
        Resource = "*"

        # CloudWatch and Logs for monitoring
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"

        # SSM and Secrets Manager for secure secret retrieval
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"

      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "devsecops_profile" {
  name = "devsecops-server-profile-${terraform.workspace}"
  role = aws_iam_role.devsecops_role.name

  tags = {
    Name        = "devsecops-server-profile-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = "DevSecOps-Pipeline"
    ManagedBy   = "Terraform"
  }
}

# DevSecOps Server EC2 Instance
resource "aws_instance" "devsecops_server" {
  # Instance configuration
  ami           = var.ami-name
  instance_type = var.devsecops_instance_type
  subnet_id     = data.aws_subnet.public.id
  key_name      = var.key-pair
  
  # IAM role for AWS service access
  iam_instance_profile = aws_iam_instance_profile.devsecops_profile.name
  
  # Security group configuration
  vpc_security_group_ids = [aws_security_group.devsecops_sg.id]
  
  # User data script for initial setup
  user_data = file("${path.module}/scripts/devsecops-setup.sh")
  
  # Root volume configuration
  root_block_device {
    volume_size           = 30  # GB - sufficient for DevSecOps tools
    volume_type           = "gp3"
    encrypted             = true  # Enable EBS encryption
    delete_on_termination = true  # Destroy volume with instance
    
    tags = merge(
      local.common_tags,
      {
        Name = "devsecops-root-volume-${var.environment}"
      }
    )
  }

  # Instance metadata service (IMDS) configuration
  metadata_options {
    http_endpoint          = "enabled"   # Enable IMDSv2
    http_tokens            = "required"  # Require session tokens
    http_put_response_hop_limit = 1      # Restrict container access to IMDS
  }

  # Resource tags
  tags = merge(
    local.common_tags,
    {
      Name = "devsecops-server-${var.environment}"
      Role = "DevSecOps-Tools"
    }
  )
}

# Elastic IP for DevSecOps server
resource "aws_eip" "devsecops_eip" {
  instance = aws_instance.devsecops_server.id
  domain   = "vpc"

  tags = {
    Name        = "devsecops-server-eip-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = "DevSecOps-Pipeline"
    ManagedBy   = "Terraform"
  }
}

# Output values
output "devsecops_server_public_ip" {
  description = "Public IP address of the DevSecOps server"
  value       = aws_eip.devsecops_eip.public_ip
}

output "devsecops_server_private_ip" {
  description = "Private IP address of the DevSecOps server"
  value       = aws_instance.devsecops_server.private_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_eip.devsecops_eip.public_ip}:8080"
}

output "sonarqube_url" {
  description = "SonarQube web interface URL"
  value       = "http://${aws_eip.devsecops_eip.public_ip}:9000"
}

output "ssh_command" {
  description = "SSH command to connect to DevSecOps server"
  value       = "ssh -i ${var.key-pair}.pem ec2-user@${aws_eip.devsecops_eip.public_ip}"
}
