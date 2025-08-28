# Complete DevSecOps Platform with Self-Hosted Infrastructure

**Status: Production Ready**

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?logo=terraform)](https://terraform.io) 
[![AWS](https://img.shields.io/badge/AWS-Free%20Tier%20Compatible-FF9900?logo=amazon-aws)](https://aws.amazon.com/free)
[![Security](https://img.shields.io/badge/Security-Hardened-brightgreen)](https://owasp.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Quick Start (5-Minute Setup)

### Prerequisites
- AWS Account with [Free Tier](https://aws.amazon.com/free) access
- AWS CLI configured with `raj-private` profile
- Terraform 1.6.6+
- SSH key pair in AWS Ireland region (eu-west-1)

### Deployment
```bash
# Clone repository
git clone https://github.com/your-org/ci-cd-project-3.git
cd ci-cd-project-3

# Initialize Terraform
terraform init

# Review changes (always review before applying!)
terraform plan \
  -var="key-pair=your-key-pair" \
  -var="allowed_ssh_cidr=your-ip/32"

# Apply configuration
terraform apply \
  -var="key-pair=your-key-pair" \
  -var="allowed_ssh_cidr=your-ip/32"
```

### First-Time Access
1. **Jenkins**: `http://<public-ip>:8080`
   - Get admin password: `ssh -i your-key.pem ec2-user@<public-ip> "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"`

2. **SonarQube**: `http://<public-ip>:9000`
   - Default credentials: admin/admin (change immediately!)

## Security Hardening (Production)

### Mandatory Changes
1. **Restrict Access**: Update these variables in `terraform.tfvars`:
   ```hcl
   allowed_ssh_cidr      = "your-ip/32"
   allowed_jenkins_cidr  = "your-ip/32"
   allowed_sonarqube_cidr= "your-ip/32"
   allowed_https_cidr    = "your-ip/32"
   allowed_http_cidr     = "your-ip/32"
   ```

2. **Secrets Management**:
   - Store sensitive values in AWS SSM Parameter Store
   - Never commit `.tfvars` files
   - Use Terraform remote state with encryption

## AWS Free Tier Compliance

### Included (Free)
- 1x t2.micro EC2 instance (750 hrs/month)
- 30GB EBS General Purpose (gp3) storage
- 5GB S3 Standard Storage
- 15GB Data Transfer OUT

### Monitoring (Optional)
- AWS CloudWatch (basic monitoring included)
- Cost Explorer: Monitor usage at hourly granularity

## Toolchain

| Tool | Version | Purpose |
|------|---------|----------|
| Jenkins | 2.414 | CI/CD Server |
| SonarQube | 9.9 (LTS) | Code Quality |
| Terraform | 1.6.6 | Infrastructure as Code |
| Docker | 24.0+ | Container Runtime |
| Python | 3.9+ | Scripting & Automation |
| Node.js | 18.x | Frontend Tooling |

## CI/CD Pipeline

### Pipeline Stages
1. **Code Checkout**
   - Git clone
   - Branch protection checks

2. **Security Scanning**
   - SAST with SonarQube
   - Dependency scanning with OWASP DC
   - Secret detection with detect-secrets

3. **Build & Test**
   - Unit tests
   - Integration tests
   - Code coverage

4. **Deployment**
   - Dev/Prod environment selection
   - Infrastructure provisioning
   - Application deployment

## Troubleshooting

### Common Issues

1. **Jenkins Not Starting**
```bash
# Check logs
sudo journalctl -u jenkins -f

# Verify Java
java -version  # Requires Java 11/17
```

2. **SonarQube Container Issues**
```bash
# Check container logs
docker logs sonarqube

# Verify system limits
ulimit -a  # Should show high file limits
```

3. **Terraform Errors**
```bash
# Initialize modules
terraform init -upgrade

# Fix state issues
terraform state list  # Verify resources
terraform refresh    # Sync state
```

## Documentation

### Project Structure
```
ci-cd-project-3/
├── scripts/               # Setup and utility scripts
├── sample-app/            # Example application
│   ├── app.py            # Sample Flask app
│   ├── requirements.txt   # Python dependencies
│   └── Dockerfile         # Container definition
├── terraform/             # Infrastructure code
│   ├── main.tf           # Core resources
│   ├── variables.tf      # Input variables
│   └── outputs.tf        # Output values
└── README.md             # This file
```

### Security Best Practices
1. **Network Security**
   - Use security groups with least privilege
   - Enable VPC flow logs
   - Use private subnets for non-public services

2. **Access Control**
   - Implement MFA for all users
   - Rotate credentials regularly
   - Use IAM roles instead of access keys

3. **Monitoring**
   - Enable CloudTrail logging
   - Set up GuardDuty
   - Configure AWS Config rules

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [OWASP](https://owasp.org/) for security best practices
- [HashiCorp](https://www.hashicorp.com/) for Terraform
- [Jenkins Community](https://www.jenkins.io/)
- [SonarSource](https://www.sonarsource.com/)
