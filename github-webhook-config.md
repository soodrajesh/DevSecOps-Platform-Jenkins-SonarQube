# GitHub Webhook Configuration Guide

This guide explains how to configure GitHub webhooks to automatically trigger the Jenkins DevSecOps pipeline when code is committed.

## Prerequisites

1. DevSecOps server running with Jenkins accessible
2. GitHub repository with your code
3. Jenkins with GitHub plugin installed
4. Public IP or domain for your Jenkins server

## Step 1: Configure Jenkins for GitHub Integration

### 1.1 Install Required Jenkins Plugins

Access Jenkins at `http://YOUR_SERVER_IP:8080` and install these plugins:

- GitHub Plugin
- GitHub Branch Source Plugin
- Pipeline: GitHub Groovy Libraries
- Generic Webhook Trigger Plugin

### 1.2 Configure GitHub Server in Jenkins

1. Go to **Manage Jenkins** → **Configure System**
2. Scroll to **GitHub** section
3. Click **Add GitHub Server**
4. Configure:
   - **Name**: `GitHub`
   - **API URL**: `https://api.github.com`
   - **Credentials**: Add GitHub personal access token
5. Test the connection and save

### 1.3 Create GitHub Personal Access Token

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens**
2. Click **Generate new token (classic)**
3. Select scopes:
   - `repo` (Full control of private repositories)
   - `admin:repo_hook` (Full control of repository hooks)
   - `user:email` (Access user email addresses)
4. Copy the token and add it to Jenkins credentials

## Step 2: Configure Jenkins Pipeline Job

### 2.1 Create Pipeline Job

1. In Jenkins, click **New Item**
2. Enter job name: `DevSecOps-Pipeline`
3. Select **Pipeline** and click **OK**

### 2.2 Configure Job Settings

**General Tab:**
- [x] GitHub project: `https://github.com/YOUR_USERNAME/YOUR_REPO`
- [x] This project is parameterized (add parameters from Jenkinsfile)

**Build Triggers:**
- [x] GitHub hook trigger for GITScm polling
- [x] Generic Webhook Trigger (optional for more control)

**Pipeline:**
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
- **Credentials**: Your GitHub credentials
- **Branches to build**: `*/main` and `*/develop`
- **Script Path**: `Jenkinsfile-DevSecOps`

### 2.3 Advanced Configuration

**Additional Behaviours:**
- Add **Clean before checkout**
- Add **Checkout to specific local branch**: `main`

## Step 3: Configure GitHub Webhook

### 3.1 Add Webhook in GitHub Repository

1. Go to your GitHub repository
2. Click **Settings** → **Webhooks**
3. Click **Add webhook**

### 3.2 Webhook Configuration

**Payload URL:**
```
http://YOUR_SERVER_IP:8080/github-webhook/
```

**Content type:** `application/json`

**Secret:** (Optional but recommended)
```
your-webhook-secret-here
```

**Which events would you like to trigger this webhook?**
- [x] Just the push event
- Or select **Let me select individual events:**
  - [x] Pushes
  - [x] Pull requests
  - [x] Pull request reviews

**Active:** [x] Checked

### 3.3 Test Webhook

1. Click **Add webhook**
2. GitHub will send a test payload
3. Check the **Recent Deliveries** tab for successful delivery

## Step 4: Security Configuration

### 4.1 Jenkins Security Settings

1. **Manage Jenkins** → **Configure Global Security**
2. **CSRF Protection**: Enable with default crumb issuer
3. **Agent protocols**: Disable deprecated protocols
4. **Markup Formatter**: Safe HTML

### 4.2 GitHub Webhook Security

Add webhook secret validation in Jenkins:

1. Install **Generic Webhook Trigger** plugin
2. Configure webhook with secret validation
3. Use the secret in GitHub webhook configuration

## Step 5: Environment Variables

Configure these environment variables in Jenkins:

### System Environment Variables
```bash
AWS_PROFILE=raj-private
AWS_REGION=eu-west-1
SONARQUBE_SERVER=http://localhost:9000
```

### Jenkins Credentials
- `github-repo-url`: Your GitHub repository URL
- `aws-credentials`: AWS access keys for raj-private profile
- `sonarqube-token`: SonarQube authentication token
- `slack-webhook`: Slack webhook URL for notifications

## Step 6: Testing the Pipeline

### 6.1 Manual Trigger Test

1. Go to your Jenkins job
2. Click **Build with Parameters**
3. Select deployment type and options
4. Click **Build**

### 6.2 Automatic Trigger Test

1. Make a small change to your repository
2. Commit and push to `main` or `develop` branch:
   ```bash
   git add .
   git commit -m "Test DevSecOps pipeline trigger"
   git push origin main
   ```
3. Check Jenkins for automatic job trigger
4. Monitor pipeline execution

## Step 7: Troubleshooting

### Common Issues

**Webhook not triggering:**
- Check GitHub webhook delivery status
- Verify Jenkins URL is accessible from internet
- Check Jenkins logs: `/var/log/jenkins/jenkins.log`

**Authentication failures:**
- Verify GitHub personal access token permissions
- Check AWS credentials configuration
- Validate SonarQube token

**Pipeline failures:**
- Check individual stage logs in Jenkins
- Verify all required tools are installed on server
- Check Terraform configuration and AWS permissions

### Useful Commands

```bash
# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Test webhook manually
curl -X POST http://YOUR_SERVER_IP:8080/github-webhook/ \
  -H "Content-Type: application/json" \
  -d '{"ref":"refs/heads/main"}'

# Check GitHub webhook deliveries
# Go to GitHub → Repository → Settings → Webhooks → Recent Deliveries
```

## Step 8: Advanced Configuration

### Multi-branch Pipeline (Recommended)

For better branch management:

1. Create **Multibranch Pipeline** instead of regular Pipeline
2. Configure branch sources to scan GitHub repository
3. Jenkins will automatically create jobs for each branch
4. Different branches can have different pipeline behaviors

### Blue Ocean Interface

Install Blue Ocean plugin for better pipeline visualization:
1. Install **Blue Ocean** plugin
2. Access via `http://YOUR_SERVER_IP:8080/blue`
3. Better visual pipeline editor and monitoring

### Notifications

Configure additional notification channels:
- Email notifications
- Microsoft Teams
- Discord
- Custom webhooks

## Security Best Practices

1. **Use HTTPS**: Configure SSL certificate for Jenkins
2. **Firewall**: Restrict access to Jenkins port (8080)
3. **Regular Updates**: Keep Jenkins and plugins updated
4. **Backup**: Regular backup of Jenkins configuration
5. **Monitoring**: Set up monitoring for Jenkins server
6. **Secrets Management**: Use Jenkins credentials store for all secrets

## Next Steps

After successful webhook configuration:

1. Set up branch protection rules in GitHub
2. Configure code review requirements
3. Add more sophisticated security scanning
4. Implement deployment strategies (blue-green, canary)
5. Set up monitoring and alerting for deployed applications
