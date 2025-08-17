#!/bin/bash

# DevSecOps Server Setup Script
# Complete automated setup for Jenkins, SonarQube, and security tools
# Version: 2.0 - Consolidated and production-ready

set -e

# Configuration
LOG_FILE="/var/log/devsecops-setup.log"
JENKINS_HOME="/var/lib/jenkins"
GITHUB_REPO="https://github.com/soodrajesh/ci-cd-project-3.git"
GITHUB_BRANCH="test-pipeline-integration"
AWS_REGION="eu-west-1"

# Logging functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Wait for service to be ready
wait_for_service() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    log "Waiting for $service to be ready on port $port..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:$port" > /dev/null 2>&1; then
            log "$service is ready on port $port"
            return 0
        fi
        sleep 10
        ((attempt++))
    done
    
    log "$service failed to start within expected time"
    return 1
}

# Main setup function
main() {
    log "Starting DevSecOps server setup..."
    
    # Update system
    log "Updating system packages..."
    yum update -y
    
    # Install basic tools
    log "Installing basic development tools..."
    yum groupinstall -y "Development Tools"
    yum install -y wget curl unzip vim htop tree jq git net-tools
    
    # Install Amazon Corretto 17 (Java 17) - Required for Jenkins
    log "Installing Amazon Corretto 17 (Java 17)..."
    yum install -y java-17-amazon-corretto java-17-amazon-corretto-devel
    
    # Configure Java 17 as default
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-amazon-corretto/bin/java 1
    update-alternatives --set java /usr/lib/jvm/java-17-amazon-corretto/bin/java
    
    # Set JAVA_HOME globally
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto' >> /etc/environment
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/environment
    export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
    export PATH=$JAVA_HOME/bin:$PATH
    
    # Configure Jenkins to use Java 17
    mkdir -p /etc/systemd/system/jenkins.service.d
    cat > /etc/systemd/system/jenkins.service.d/java17.conf << EOF
[Service]
Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto"
Environment="PATH=/usr/lib/jvm/java-17-amazon-corretto/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF
    
    log "Java 17 installation and configuration completed"
    
    # Install Jenkins
    log "Installing Jenkins..."
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install -y jenkins
    
    # Start Jenkins
    systemctl daemon-reload
    systemctl enable jenkins
    systemctl start jenkins
    
    # Wait for Jenkins to initialize
    log "Waiting for Jenkins to initialize..."
    for i in {1..12}; do
        if [ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]; then
            JENKINS_PASSWORD=$(cat "$JENKINS_HOME/secrets/initialAdminPassword")
            log "Jenkins initialized successfully. Admin password: $JENKINS_PASSWORD"
            break
        fi
        log "Waiting for Jenkins initialization... ($i/12)"
        sleep 10
    done
    
    # Install Docker
    log "Installing Docker..."
    yum install -y docker
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user
    usermod -aG docker jenkins
    
    # Install Docker Compose
    log "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    # Install Python 3 and security tools
    log "Installing Python 3 and security tools..."
    yum install -y python3 python3-pip
    python3 -m pip install --upgrade pip
    
    # Install security tools for ec2-user
    sudo -u ec2-user bash << 'USER_SCRIPT'
    export PATH="$HOME/.local/bin:$PATH"
    pip3 install --user checkov bandit safety detect-secrets semgrep 2>/dev/null || echo "Some security tools failed to install"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
USER_SCRIPT
    
    # Install Node.js and Snyk
    log "Installing Node.js..."
    curl -sL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs
    npm install -g snyk || log "Snyk installation failed"
    
    # Install AWS CLI v2
    if ! command -v aws >/dev/null 2>&1; then
        log "Installing AWS CLI v2..."
        cd /tmp
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
        rm -rf aws awscliv2.zip
    fi
    
    # Install Terraform
    if ! command -v terraform >/dev/null 2>&1; then
        log "Installing Terraform..."
        TERRAFORM_VERSION="1.6.6"
        cd /tmp
        wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        mv terraform /usr/local/bin/
        chmod +x /usr/local/bin/terraform
        rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    fi
    
    # Setup SonarQube with Docker
    log "Setting up SonarQube..."
    mkdir -p /opt/sonarqube
    cd /opt/sonarqube
    
    # Set kernel parameters for SonarQube
    echo 'vm.max_map_count=524288' >> /etc/sysctl.conf
    echo 'fs.file-max=131072' >> /etc/sysctl.conf
    sysctl -p
    
    # Create docker-compose.yml for SonarQube
    cat > docker-compose.yml << EOF
version: '3.8'
services:
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    restart: unless-stopped
    environment:
      SONAR_JDBC_URL: jdbc:h2:mem:sonar
    ports:
      - "9000:9000"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    mem_limit: 1g

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
EOF
    
    # Start SonarQube
    docker-compose up -d
    log "SonarQube container started"
    
    # Configure Jenkins plugins and jobs
    log "Configuring Jenkins..."
    wait_for_service "Jenkins" 8080
    
    if [ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]; then
        JENKINS_PASSWORD=$(cat "$JENKINS_HOME/secrets/initialAdminPassword")
        
        # Install essential plugins
        log "Installing Jenkins plugins..."
        PLUGINS="git workflow-aggregator pipeline-stage-view blueocean sonar github"
        
        for plugin in $PLUGINS; do
            curl -s -X POST -u "admin:$JENKINS_PASSWORD" \
                "http://localhost:8080/pluginManager/installNecessaryPlugins" \
                -d "<jenkins><install plugin='$plugin@latest' /></jenkins>" \
                -H "Content-Type: text/xml" || log "Failed to install $plugin"
        done
        
        # Restart Jenkins to load plugins
        systemctl restart jenkins
        sleep 30
        
        # Create simple test pipeline job
        log "Creating DevSecOps-Test pipeline job..."
        cat > /tmp/test-pipeline-config.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Simple DevSecOps Test Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.92">
    <script>
pipeline {
    agent any
    stages {
        stage('Environment Check') {
            steps {
                echo '🔧 DevSecOps Environment Check'
                sh 'echo "Java: $(java -version 2>&1 | head -n1)"'
                sh 'echo "Python: $(python3 --version)"'
                sh 'echo "Docker: $(docker --version)"'
                sh 'echo "AWS CLI: $(aws --version 2>/dev/null || echo Not installed)"'
                echo '✅ Environment check completed'
            }
        }
        stage('Security Tools Check') {
            steps {
                echo '🛡️ Security Tools Verification'
                sh 'which python3 || echo "Python3 not in PATH"'
                sh 'ls -la /home/ec2-user/.local/bin/ 2>/dev/null || echo "No user local bin"'
                echo '✅ Security tools check completed'
            }
        }
        stage('Success') {
            steps {
                echo '🎉 DevSecOps Test Pipeline Completed Successfully!'
            }
        }
    }
}
    </script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
        
        # Get CSRF crumb and create job
        CRUMB=$(curl -s -u "admin:$JENKINS_PASSWORD" \
            "http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
        
        if [ -n "$CRUMB" ]; then
            curl -s -X POST -u "admin:$JENKINS_PASSWORD" \
                -H "$CRUMB" \
                -H 'Content-Type: application/xml' \
                --data-binary @/tmp/test-pipeline-config.xml \
                "http://localhost:8080/createItem?name=DevSecOps-Test" && \
                log "DevSecOps-Test job created successfully"
        fi
        
        rm -f /tmp/test-pipeline-config.xml
    fi
    
    # Create monitoring script
    log "Creating DevSecOps monitoring script..."
    cat > /home/ec2-user/monitor-devsecops.sh << 'EOF'
#!/bin/bash

# DevSecOps Platform Status Monitor
echo "=== DevSecOps Platform Status ==="
echo "Time: $(date)"
echo "Host: $(hostname -I | awk '{print $1}')"
echo ""

# Jenkins Status
echo "🔧 Jenkins Status:"
if systemctl is-active --quiet jenkins; then
    echo "  ✅ Service: Running"
    if curl -s -f http://localhost:8080/login > /dev/null; then
        echo "  ✅ Web Interface: Accessible at http://$(hostname -I | awk '{print $1}'):8080"
        if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
            echo "  🔑 Admin Password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
        fi
    else
        echo "  ❌ Web Interface: Not accessible"
    fi
else
    echo "  ❌ Service: Not running"
fi
echo ""

# SonarQube Status
echo "🔍 SonarQube Status:"
if docker ps --filter "name=sonarqube" --format "{{.Status}}" | grep -q "Up"; then
    echo "  ✅ Container: Running"
    echo "  🌐 Web Interface: http://$(hostname -I | awk '{print $1}'):9000"
else
    echo "  ❌ Container: Not running"
fi
echo ""

# System Resources
echo "💻 System Resources:"
echo "  CPU: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1)%"
echo "  Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "  Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
echo ""

# Security Tools
echo "🛡️ Security Tools:"
for tool in checkov bandit safety detect-secrets semgrep snyk; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  ✅ $tool: Available"
    else
        echo "  ❌ $tool: Not available"
    fi
done
echo ""

echo "📋 Quick Access:"
echo "  Jenkins: http://$(hostname -I | awk '{print $1}'):8080 (admin/$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'password-not-found'))"
echo "  SonarQube: http://$(hostname -I | awk '{print $1}'):9000 (admin/admin)"
echo "  SSH: ssh -i ~/Downloads/opsworx-ie.pem ec2-user@$(hostname -I | awk '{print $1}')"
EOF
    
    chmod +x /home/ec2-user/monitor-devsecops.sh
    chown ec2-user:ec2-user /home/ec2-user/monitor-devsecops.sh
    
    # Setup GitHub webhook automation (delayed)
    log "Setting up delayed GitHub webhook automation..."
    cat > /tmp/github-webhook-delayed.sh << 'EOF'
#!/bin/bash

# Wait for Jenkins to be fully ready
sleep 180

LOG_FILE="/var/log/github-webhook-setup.log"
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
AWS_REGION="eu-west-1"
GITHUB_REPO="https://github.com/soodrajesh/ci-cd-project-3.git"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting GitHub webhook setup..."

# Get Jenkins password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
    
    # Get GitHub token from AWS Parameter Store
    GITHUB_TOKEN=$(aws ssm get-parameter --name "/github-auto-commit/github-token" --with-decryption --region "$AWS_REGION" --query 'Parameter.Value' --output text 2>/dev/null)
    
    if [ -n "$GITHUB_TOKEN" ] && [ "$GITHUB_TOKEN" != "None" ]; then
        log "Retrieved GitHub token from Parameter Store"
        
        # Configure GitHub webhook
        WEBHOOK_URL="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080/github-webhook/"
        
        curl -s -X POST \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"name\": \"web\",
                \"active\": true,
                \"events\": [\"push\", \"pull_request\"],
                \"config\": {
                    \"url\": \"$WEBHOOK_URL\",
                    \"content_type\": \"json\",
                    \"insecure_ssl\": \"1\"
                }
            }" \
            "https://api.github.com/repos/soodrajesh/ci-cd-project-3/hooks" && \
            log "GitHub webhook configured successfully" || \
            log "GitHub webhook configuration failed"
    else
        log "GitHub token not available in Parameter Store"
    fi
else
    log "Jenkins password not available"
fi
EOF
    
    chmod +x /tmp/github-webhook-delayed.sh
    nohup /tmp/github-webhook-delayed.sh &
    
    # Final setup completion
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    
    log "=== DevSecOps Platform Setup Complete ==="
    log "Jenkins: http://$PUBLIC_IP:8080"
    log "SonarQube: http://$PUBLIC_IP:9000"
    log "Monitor: /home/ec2-user/monitor-devsecops.sh"
    log "Setup log: $LOG_FILE"
    
    # Create completion marker
    echo "DevSecOps setup completed at $(date)" > /home/ec2-user/devsecops-setup-complete.txt
    chown ec2-user:ec2-user /home/ec2-user/devsecops-setup-complete.txt
    
    log "🎉 DevSecOps platform is ready for use!"
}

# Execute main function
main "$@" 2>&1 | tee -a "$LOG_FILE"
