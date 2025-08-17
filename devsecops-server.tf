# DevSecOps Server - EC2 instance with all tools pre-installed
# This creates a complete DevSecOps environment with Jenkins, SonarQube, OWASP, etc.

resource "aws_security_group" "devsecops_sg" {
  name_prefix = "devsecops-server-${terraform.workspace}"
  description = "Security group for DevSecOps server"
  vpc_id      = data.aws_vpc.existing.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins web interface"
  }

  # SonarQube
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SonarQube web interface"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
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
        Action = [
          "ec2:*",
          "s3:*",
          "iam:*",
          "lambda:*",
          "cloudformation:*",
          "logs:*",
          "cloudwatch:*",
          "sns:*",
          "sqs:*",
          "dynamodb:*",
          "rds:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "route53:*",
          "acm:*",
          "secretsmanager:*",
          "ssm:*",
          "sts:*"
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
  ami                    = var.ami-name
  instance_type          = var.devsecops_instance_type
  subnet_id              = data.aws_subnet.public.id
  key_name               = var.key-pair
  iam_instance_profile   = aws_iam_instance_profile.devsecops_profile.name
  vpc_security_group_ids = [aws_security_group.devsecops_sg.id]
  
  user_data = file("${path.module}/scripts/devsecops-setup.sh")
  
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "DevSecOps-Server-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = "DevSecOps-Pipeline"
    ManagedBy   = "Terraform"
    Role        = "DevSecOps-Tools"
  }
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
