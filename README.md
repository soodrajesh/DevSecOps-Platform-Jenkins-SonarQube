# Complete DevSecOps Platform with Self-Hosted Infrastructure

**Status: Production Ready** 🎉

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Ireland%20Region-FF9900?logo=amazon-aws)](https://aws.amazon.com)
[![Jenkins](https://img.shields.io/badge/Jenkins-2.400+-D33833?logo=jenkins)](https://jenkins.io)
[![Security](https://img.shields.io/badge/Security-DevSecOps-green)](https://owasp.org)
[![SonarQube](https://img.shields.io/badge/SonarQube-Community-4E9BCD?logo=sonarqube)](https://sonarqube.org)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker)](https://docker.com)

**A complete, automated DevSecOps platform** that provisions an EC2 server with Jenkins, SonarQube, and security tools pre-installed. Features GitHub webhook integration, comprehensive security scanning, and automated CI/CD pipelines.

🎯 **Perfect for**: Teams wanting enterprise-grade DevSecOps that deploys with a single command and includes all manual fixes documented in automation scripts.

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
   # Configure with your AWS credentials for Ireland region (eu-west-1)
   ```

2. **Required AWS Resources** (Ireland - eu-west-1):
   - EC2 Key Pair: `opsworx-ie` (download to ~/Downloads/)
   - VPC and subnets (existing infrastructure)
   - Security groups with proper access rules
   - IAM roles for EC2 instances

3. **Optional GitHub Integration**:
   ```bash
   # Store GitHub token for automated webhook setup
   aws ssm put-parameter \
     --name "/github-auto-commit/github-token" \
     --value "your-github-token" \
     --type "SecureString" \
     --region eu-west-1 \
     --profile raj-private
   ```

### Automated Jenkins Configuration
1. **Essential Plugins Pre-installed**:
   - Git, Pipeline, Blue Ocean
   - SonarQube Scanner, GitHub integration
   - AWS Steps for cloud deployment

2. **Pre-configured Jobs**:
   - `DevSecOps-Test`: Simple validation pipeline
   - `DevSecOps-Pipeline`: Comprehensive security pipeline (auto-created)

3. **Security Tools Ready**:
   - Checkov, Bandit, Safety, detect-secrets, Semgrep
   - All tools installed in user space with proper PATH configuration

## 🚀 Quick Start Guide

### Step 1: Prerequisites Setup
```bash
# 1. Configure AWS CLI with raj-private profile
aws configure --profile raj-private
# Enter your AWS credentials for Ireland region (eu-west-1)

# 2. Clone the repository
git clone https://github.com/soodrajesh/ci-cd-project-3.git
cd ci-cd-project-3

# 3. Ensure you have the SSH key
# Download opsworx-ie.pem to ~/Downloads/
# Set correct permissions: chmod 400 ~/Downloads/opsworx-ie.pem
```

### Step 2: Deploy DevSecOps Infrastructure
```bash
# Deploy complete DevSecOps platform
terraform init
terraform plan
terraform apply

# The deployment includes:
# - EC2 instance with automated setup
# - Jenkins with plugins and jobs pre-configured
# - SonarQube container
# - All security tools installed
# - GitHub webhook integration
```

### Step 3: Access Your DevSecOps Platform
```bash
# After deployment completes (8-10 minutes):
# Jenkins: http://YOUR_SERVER_IP:8080
# SonarQube: http://YOUR_SERVER_IP:9000

# SSH to server and check status:
ssh -i ~/Downloads/opsworx-ie.pem ec2-user@YOUR_SERVER_IP
./monitor-devsecops.sh

# Get Jenkins credentials from the monitoring script output
```

### Step 4: GitHub Integration (Automated)
```bash
# GitHub webhook is automatically configured if you have:
# 1. GitHub token stored in AWS Parameter Store: /github-auto-commit/github-token
# 2. The setup script handles webhook creation automatically

# To manually add GitHub token to Parameter Store:
aws ssm put-parameter \
  --name "/github-auto-commit/github-token" \
  --value "your-github-token" \
  --type "SecureString" \
  --region eu-west-1 \
  --profile raj-private
```

### Step 5: Test the Complete Workflow
```bash
# The comprehensive DevSecOps pipeline includes:
# - Environment setup and tool validation
# - Security scanning (Checkov, Bandit, Safety)
# - Code analysis and infrastructure validation
# - Build testing and deployment readiness

# Test by making a commit:
echo "# DevSecOps Test" > test-file.md
git add test-file.md
git commit -m "Test: Trigger comprehensive DevSecOps pipeline"
git push origin test-pipeline-integration

# Monitor pipeline execution in Jenkins!
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
├── .gitignore                    # Git ignore patterns
│
├── 🏗️ Infrastructure (Terraform)
├── main.tf                       # Application infrastructure
├── devsecops-server.tf          # DevSecOps server with all tools
├── backend.tf                   # Terraform backend configuration
├── providers.tf                 # AWS provider configuration
├── vars.tf                      # Variable definitions
├── outputs.tf                   # Output definitions
│
├── 🔄 CI/CD Pipeline
├── Jenkinsfile                  # Comprehensive DevSecOps pipeline
│
├── 📱 Sample Application
├── sample-app/
│   ├── app.py                   # Flask web application
│   ├── requirements.txt         # Python dependencies
│   └── Dockerfile              # Container configuration
│
├── 🛠️ Scripts & Automation
├── scripts/
│   ├── devsecops-setup-clean.sh    # Production-ready setup script
│   ├── monitor-devsecops.sh         # Status monitoring (created on EC2)
│   ├── test-comprehensive-pipeline.sh # Pipeline testing
│   ├── check-jenkins-status.sh      # Jenkins status checker
│   └── run-on-ec2.sh               # Remote execution helper
│
└── 📚 Documentation
    └── All manual fixes documented in automation scripts
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

## 🔧 Key Features & Manual Fixes Automated

### All Manual Fixes Documented in Scripts
- **Java 17 Configuration**: Automated in `devsecops-setup-clean.sh`
- **Jenkins Plugin Installation**: Automated with proper error handling
- **SonarQube Container Setup**: Docker Compose with proper resource limits
- **Security Tools Installation**: User-space installation for ec2-user
- **GitHub Webhook Integration**: Automated with AWS Parameter Store
- **Pipeline Job Creation**: Comprehensive DevSecOps pipeline pre-configured

### Comprehensive DevSecOps Pipeline Stages
1. **Environment Setup**: Tool validation and workspace check
2. **Security Tools Check**: Verify security scanning tools availability
3. **Code Analysis**: File analysis and secret detection
4. **Infrastructure Validation**: Terraform syntax and formatting
5. **Security Scanning**: Permission checks and hardcoded secret detection
6. **Code Quality Analysis**: SonarQube integration when available
7. **Infrastructure Security**: Public access and encryption validation
8. **Build & Test**: Python syntax and shell script validation
9. **Deployment Ready**: Complete pipeline summary

### Monitoring & Status
- **Real-time Monitoring**: `monitor-devsecops.sh` script on EC2
- **Remote Execution**: `run-on-ec2.sh` for local testing
- **Pipeline Testing**: Automated pipeline trigger and monitoring

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
