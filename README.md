# Complete DevSecOps Platform with Self-Hosted Infrastructure

**Status: Pipeline Testing in Progress** ✅

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Ireland%20Region-FF9900?logo=amazon-aws)](https://aws.amazon.com)
[![Jenkins](https://img.shields.io/badge/Jenkins-Pipeline-D33833?logo=jenkins)](https://jenkins.io)
[![Security](https://img.shields.io/badge/Security-DevSecOps-green)](https://owasp.org)
[![SonarQube](https://img.shields.io/badge/SonarQube-Code%20Quality-4E9BCD?logo=sonarqube)](https://sonarqube.org)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker)](https://docker.com)

**A complete, self-contained DevSecOps platform** that automatically provisions an EC2 server with all necessary tools pre-installed (Jenkins, SonarQube, OWASP, Checkov, Terraform) and creates a GitHub webhook-triggered pipeline for secure infrastructure and application deployment.

🎯 **Perfect for**: Teams wanting a complete DevSecOps solution that deploys with a single `terraform apply` command.

![CI/CD Architecture](ci-cd-3.png)

## 🏗️ Complete DevSecOps Architecture

This platform creates a **fully automated DevSecOps environment** with:

### 🖥️ **Self-Hosted DevSecOps Server**
- **Automated EC2 Provisioning**: Single-command deployment of complete toolchain
- **Pre-installed Tools**: Jenkins, SonarQube, OWASP, Checkov, Terraform, Docker
- **Auto-configuration**: All tools configured and ready to use
- **Persistent Storage**: EBS volumes with encryption for data persistence

### 🔄 **Automated CI/CD Workflow**
- **GitHub Integration**: Webhook-triggered pipelines on code commits
- **Multi-Environment**: Automatic dev/prod environment selection based on branches
- **Security-First**: Integrated security scanning at every pipeline stage
- **Infrastructure as Code**: Complete infrastructure deployment via Terraform

### 🛡️ **Comprehensive Security Scanning**
- **Static Code Analysis**: SonarQube integration with quality gates
- **Infrastructure Security**: Checkov for IaC security validation
- **Dependency Scanning**: OWASP Dependency Check for vulnerabilities
- **Secret Detection**: Automated secret scanning and validation

### 📊 **Monitoring & Notifications**
- **Real-time Alerts**: Slack integration for build status
- **Health Monitoring**: Automated post-deployment validation
- **Performance Testing**: Basic performance validation
- **Security Compliance**: Continuous security posture monitoring

## 🚀 Key Features

### 🎯 **One-Command Deployment**
- ✅ **Complete Infrastructure**: Single `terraform apply` deploys entire DevSecOps platform
- ✅ **Auto-Configuration**: All tools pre-configured and integrated
- ✅ **Ready-to-Use**: Access Jenkins and SonarQube immediately after deployment

### 🔒 **Enterprise Security**
- ✅ **Multi-Layer Security Scanning**: SonarQube + Checkov + OWASP + Secret Detection
- ✅ **Encrypted Storage**: All EBS volumes encrypted at rest
- ✅ **Security Groups**: Properly configured network access controls
- ✅ **IMDSv2 Enforcement**: Secure instance metadata access

### 🌍 **Production-Ready**
- ✅ **Ireland Region (eu-west-1)**: GDPR-compliant EU deployment
- ✅ **High Availability**: Elastic IP and proper backup strategies
- ✅ **Monitoring**: Comprehensive health checks and alerting
- ✅ **Scalable**: Designed for team collaboration

### 🔄 **Developer Experience**
- ✅ **GitHub Integration**: Automatic pipeline triggers on commits
- ✅ **Branch-Based Deployment**: Dev/prod environments based on Git branches
- ✅ **Visual Pipeline**: Blue Ocean interface for better UX
- ✅ **Sample Application**: Ready-to-deploy Flask app for testing

## 📋 Prerequisites

### Required Tools
- **Jenkins** (v2.400+) with required plugins:
  - Pipeline Plugin
  - AWS Steps Plugin
  - SonarQube Scanner Plugin
  - OWASP Dependency-Check Plugin
  - Slack Notification Plugin
- **Terraform** (v1.0+)
- **AWS CLI** (v2.0+)
- **Python 3** with pip
- **Git**

### AWS Configuration
1. **AWS Profile Setup**:
   ```bash
   aws configure --profile raj-private
   # Configure with your AWS credentials for Ireland region
   ```

2. **Required AWS Resources** (Ireland - eu-west-1):
   - S3 bucket for Terraform state: `demo-tf-state-rsood`
   - DynamoDB table for state locking: `demo-tf-state-lock`
   - VPC with private subnet
   - Security group for EC2 access
   - IAM role for EC2 instances
   - EC2 Key Pair: `raj-private-ireland`

3. **IAM Permissions**:
   - EC2 full access
   - S3 access for state management
   - DynamoDB access for state locking
   - IAM role assumption capabilities

### Jenkins Configuration
1. **Credentials Setup**:
   - `aws-dev-user`: AWS credentials for development
   - `aws-prod-user`: AWS credentials for production
   - `SonarQube`: SonarQube authentication token
   - `snyk-token-soodrajesh`: Snyk security scanning token

2. **Tool Configuration**:
   - SonarQube server configuration
   - OWASP Dependency-Check installation
   - Slack workspace integration

## 🚀 Quick Start Guide

### Step 1: Prerequisites Setup
```bash
# 1. Configure AWS CLI with raj-private profile
aws configure --profile raj-private
# Enter your AWS credentials for Ireland region (eu-west-1)

# 2. Clone the repository
git clone <your-repo-url>
cd ci-cd-project-3

# 3. Update configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual AWS resource IDs
```

### Step 2: Deploy DevSecOps Infrastructure
```bash
# Deploy complete DevSecOps platform
terraform init
terraform plan
terraform apply

# Note the outputs - you'll need the Jenkins and SonarQube URLs
```

### Step 3: Access Your DevSecOps Platform
```bash
# After deployment completes (5-10 minutes):
# Jenkins: http://YOUR_SERVER_IP:8080
# SonarQube: http://YOUR_SERVER_IP:9000

# Get Jenkins initial password:
ssh -i your-key.pem ec2-user@YOUR_SERVER_IP
cat /home/ec2-user/devsecops-setup-complete.txt
```

### Step 4: Configure GitHub Integration
```bash
# Follow the detailed guide:
cat github-webhook-config.md

# Key steps:
# 1. Add GitHub webhook pointing to your Jenkins server
# 2. Configure Jenkins pipeline job
# 3. Test with a commit to trigger the pipeline
```

### Step 5: Test the Complete Workflow
```bash
# Make a test commit to trigger the pipeline
echo "# Test# DevSecOps CI/CD Pipeline Project

**Status: Pipeline Testing in Progress** ✅-file.md
git add test-file.md
git commit -m "Test: Trigger DevSecOps pipeline"
git push origin main

# Watch the pipeline execute in Jenkins!
```

## 📊 Pipeline Stages

### 1. **Checkout** 📥
Fetches the latest code from the version control system.

### 2. **Dependency Validation** ✅
- Validates Terraform installation and version
- Checks AWS CLI and profile configuration
- Verifies Python and pip availability
- Tests AWS credentials and permissions

### 3. **Security Tools Installation** 🔧
- Installs Checkov for infrastructure security scanning
- Verifies tool installations and versions

### 4. **Terraform Initialization** 🏗️
- Initializes Terraform with remote backend
- Handles state migration prompts automatically

### 5. **Workspace Management** 🔄
- Selects appropriate workspace based on Git branch
- Creates new workspaces if they don't exist
- Development: `develop` branch → `development` workspace
- Production: `main` branch → `production` workspace

### 6. **OWASP Dependency Check** 🛡️
- Scans for known vulnerabilities in dependencies
- Generates comprehensive security reports
- Publishes results for review

### 7. **SonarQube Analysis** 📊
- Performs static code analysis on Terraform files
- Checks code quality and security issues
- Integrates with SonarQube dashboard

### 8. **Checkov Security Scan** 🔍
- Infrastructure as Code security scanning
- Validates against CIS benchmarks
- Configurable security checks via `skip_checks.txt`

### 9. **Terraform Plan** 📋
- Generates execution plan for infrastructure changes
- Validates configuration and dependencies
- Outputs plan for manual review

### 10. **Manual Approval** ⏸️
- Requires manual approval before applying changes
- Provides opportunity to review planned changes
- Production safety gate

### 11. **Terraform Apply** 🚀
- Applies approved infrastructure changes
- Uses appropriate AWS credentials per environment
- Sends success notifications to Slack

## 🔒 Security Features

### Infrastructure Security
- **Encrypted EBS volumes**: All storage encrypted at rest
- **IMDSv2 enforcement**: Secure instance metadata access
- **VPC security groups**: Network-level access controls
- **IAM roles**: Least privilege access principles

### Pipeline Security
- **Credential management**: Secure Jenkins credential storage
- **Multi-stage scanning**: Security checks at every stage
- **Approval gates**: Manual verification for production
- **Audit logging**: Complete deployment audit trail

### Compliance
- **GDPR compliant**: Ireland region deployment
- **CIS benchmarks**: Infrastructure security standards
- **OWASP guidelines**: Application security best practices

## 📁 Complete Project Structure

```
ci-cd-project-3/
├── README.md                      # This comprehensive guide
├── ci-cd-3.png                   # Architecture diagram
├── .gitignore                    # Git ignore patterns
│
├── 🏗️ Infrastructure (Terraform)
├── main.tf                       # Application infrastructure
├── devsecops-server.tf          # DevSecOps server with all tools
├── backend.tf                   # Terraform backend configuration
├── providers.tf                 # AWS provider configuration
├── vars.tf                      # Variable definitions
├── outputs.tf                   # Output definitions
├── terraform.tfvars.example     # Example variables file
│
├── 🔄 CI/CD Pipeline
├── Jenkinsfile                  # Original pipeline
├── Jenkinsfile-DevSecOps        # Complete DevSecOps pipeline
├── github-webhook-config.md     # GitHub integration guide
├── skip_checks.txt             # Checkov skip configurations
│
├── 📱 Sample Application
├── sample-app/
│   ├── app.py                   # Flask web application
│   ├── requirements.txt         # Python dependencies
│   └── Dockerfile              # Container configuration
│
├── 🛠️ Scripts & Automation
├── scripts/
│   ├── devsecops-setup.sh      # Complete tool installation
│   ├── validate-dependencies.sh # Dependency validation
│   ├── deploy.sh               # Manual deployment
│   └── post-deployment-tests.sh # Validation & testing
│
└── 📚 Legacy Files
    ├── app1-install.sh          # Original EC2 user data
    └── Jenkinsfile              # Original pipeline
```

## 🌍 Environment Configuration

### Development Environment
- **Branch**: `develop`
- **Workspace**: `development`
- **AWS Region**: `eu-west-1`
- **Instance Tags**: `Environment=development`

### Production Environment
- **Branch**: `main`
- **Workspace**: `production`
- **AWS Region**: `eu-west-1`
- **Instance Tags**: `Environment=production`

## 📈 Monitoring & Notifications

### Slack Integration
Real-time notifications for:
- ✅ Successful deployments
- ❌ Failed builds
- ⚠️ Unstable builds
- 🛑 Aborted builds

### Jira Integration
Automatic issue tracking and status updates.

## 🔧 Customization

### Adding New Environments
1. Update `Jenkinsfile` with new branch conditions
2. Create corresponding Terraform workspace
3. Configure environment-specific variables

### Modifying Security Checks
Edit `skip_checks.txt` to customize Checkov security validations:
```
CKV_AWS_126,CKV_AWS_135,CKV_AWS_79,CKV_AWS_8
```

### Custom Deployment Scripts
Modify `scripts/deploy.sh` for additional deployment logic or validation steps.

## 🚨 Troubleshooting Guide

### Infrastructure Deployment Issues

**1. AWS Profile Configuration**
```bash
# Configure AWS profile
aws configure --profile raj-private
# Test configuration
aws sts get-caller-identity --profile raj-private
```

**2. Terraform State Issues**
```bash
# Unlock state if locked
terraform force-unlock <LOCK_ID>

# Refresh state
terraform refresh

# Import existing resources if needed
terraform import aws_instance.example i-1234567890abcdef0
```

**3. Missing AWS Resources**
```bash
# Create VPC and subnets if needed
aws ec2 describe-vpcs --profile raj-private --region eu-west-1
aws ec2 describe-subnets --profile raj-private --region eu-west-1

# Update terraform.tfvars with actual resource IDs
```

### DevSecOps Server Issues

**1. Server Not Accessible**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx --profile raj-private

# Verify instance is running
aws ec2 describe-instances --instance-ids i-xxxxx --profile raj-private

# Check system status
aws ec2 describe-instance-status --instance-ids i-xxxxx --profile raj-private
```

**2. Jenkins Not Starting**
```bash
# SSH to server and check logs
ssh -i your-key.pem ec2-user@YOUR_SERVER_IP
sudo systemctl status jenkins
sudo journalctl -u jenkins -f

# Restart Jenkins
sudo systemctl restart jenkins
```

**3. SonarQube Issues**
```bash
# Check Docker containers
docker ps -a
docker logs sonarqube

# Restart SonarQube
cd /opt/sonarqube
sudo docker-compose restart
```

### Pipeline Issues

**1. GitHub Webhook Not Triggering**
```bash
# Check webhook deliveries in GitHub
# Repository → Settings → Webhooks → Recent Deliveries

# Test webhook manually
curl -X POST http://YOUR_SERVER_IP:8080/github-webhook/ \
  -H "Content-Type: application/json" \
  -d '{"ref":"refs/heads/main"}'
```

**2. Pipeline Failures**
```bash
# Check Jenkins build logs
# Navigate to failed build → Console Output

# Run validation script manually
./scripts/validate-dependencies.sh

# Test individual pipeline stages
./scripts/post-deployment-tests.sh
```

### Useful Diagnostic Commands

```bash
# Complete system status check
ssh -i your-key.pem ec2-user@YOUR_SERVER_IP
./monitor-services.sh

# Validate all configurations
./scripts/validate-dependencies.sh

# Test infrastructure
./scripts/post-deployment-tests.sh

# Check Terraform state
terraform show
terraform output
```

### Emergency Recovery

**Complete Infrastructure Reset:**
```bash
# Destroy and recreate (CAUTION: This will delete everything)
terraform destroy
terraform apply

# Or just recreate the DevSecOps server
terraform destroy -target=aws_instance.devsecops_server
terraform apply -target=aws_instance.devsecops_server
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run validation scripts
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🏷️ Tags

`DevSecOps` `Jenkins` `SonarQube` `Terraform` `AWS` `CI/CD` `Infrastructure-as-Code` `Security-Scanning` `OWASP` `Checkov` `Docker` `GitHub-Webhooks` `Automation` `Ireland` `GDPR-Compliant` `Self-Hosted` `Complete-Platform`

---

## 🎯 What You Get

After running `terraform apply`, you'll have:

### 🖥️ **Complete DevSecOps Server**
- **Jenkins**: `http://YOUR_SERVER_IP:8080` (with all plugins pre-installed)
- **SonarQube**: `http://YOUR_SERVER_IP:9000` (ready for code analysis)
- **All Security Tools**: Checkov, OWASP, Snyk, Secret Detection
- **Development Tools**: Terraform, AWS CLI, Docker, Python

### 🔄 **Automated Pipeline**
- **GitHub Integration**: Webhook triggers on every commit
- **Multi-Environment**: Automatic dev/prod deployment based on branches
- **Security Gates**: Comprehensive security scanning before deployment
- **Approval Workflow**: Manual approval for production deployments

### 📱 **Sample Application**
- **Flask Web App**: Ready-to-deploy sample application
- **Docker Support**: Containerized deployment option
- **Health Checks**: Built-in monitoring endpoints
- **Security Headers**: Production-ready security configuration

### 📊 **Monitoring & Reporting**
- **Real-time Notifications**: Slack integration for build status
- **Test Reports**: Automated post-deployment validation
- **Security Reports**: Comprehensive security scan results
- **Performance Metrics**: Basic performance monitoring

---

## 🏆 Success Metrics

**Deployment Time**: ~10 minutes from `terraform apply` to fully functional DevSecOps platform

**Security Coverage**: 4 layers of security scanning (Static Analysis, IaC Security, Dependency Check, Secret Detection)

**Automation Level**: 100% automated from code commit to production deployment

**Team Productivity**: Developers can focus on code while security and deployment are handled automatically

---

**🚀 Built for teams who want enterprise-grade DevSecOps without the complexity**

*Deploy once, develop forever!*
