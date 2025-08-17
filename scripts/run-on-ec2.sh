#!/bin/bash

# Run DevSecOps Pipeline Tests on EC2 Instance
# This script connects to the EC2 instance and executes our pipeline tests

set -e

# Configuration
AWS_PROFILE="raj-private"
AWS_REGION="eu-west-1"
KEY_PATH="$HOME/Downloads/opsworx-ie.pem"  # Using the correct AWS key pair
EC2_USER="ec2-user"

echo "🚀 Running DevSecOps Pipeline Tests on EC2..."

# Function to get EC2 instance IP
get_ec2_instance_ip() {
    echo "🔍 Finding DevSecOps EC2 instance..."
    
    local instance_ip=$(aws ec2 describe-instances \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --filters "Name=tag:Name,Values=DevSecOps-Server-default" \
                  "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    
    if [ "$instance_ip" = "None" ] || [ "$instance_ip" = "null" ] || [ -z "$instance_ip" ]; then
        echo "❌ No running DevSecOps EC2 instance found"
        return 1
    fi
    
    echo "✅ Found EC2 instance: $instance_ip"
    echo "$instance_ip"
}

# Function to check SSH connectivity
check_ssh_connection() {
    local instance_ip=$1
    
    echo "🔐 Testing SSH connection to $instance_ip..."
    
    if ssh -i "$KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
           "$EC2_USER@$instance_ip" "echo 'SSH connection successful'"; then
        echo "✅ SSH connection established"
        return 0
    else
        echo "❌ SSH connection failed"
        echo "💡 Make sure:"
        echo "   - SSH key path is correct: $KEY_PATH"
        echo "   - Security group allows SSH (port 22)"
        echo "   - Instance is running and accessible"
        return 1
    fi
}

# Function to upload scripts to EC2
upload_scripts() {
    local instance_ip=$1
    
    echo "📤 Uploading scripts to EC2 instance..."
    
    # Create remote directory
    ssh -i "$KEY_PATH" "$EC2_USER@$instance_ip" "mkdir -p ~/ci-cd-project-3/scripts"
    
    # Upload our test scripts
    scp -i "$KEY_PATH" \
        "$(dirname "$0")/test-comprehensive-pipeline.sh" \
        "$(dirname "$0")/check-jenkins-status.sh" \
        "$EC2_USER@$instance_ip:~/ci-cd-project-3/scripts/"
    
    # Make scripts executable
    ssh -i "$KEY_PATH" "$EC2_USER@$instance_ip" \
        "chmod +x ~/ci-cd-project-3/scripts/*.sh"
    
    echo "✅ Scripts uploaded successfully"
}

# Function to run Jenkins status check on EC2
run_jenkins_status_check() {
    local instance_ip=$1
    
    echo "🔍 Running Jenkins status check on EC2..."
    
    ssh -i "$KEY_PATH" "$EC2_USER@$instance_ip" << 'EOF'
        echo "=== Jenkins Status Check on EC2 ==="
        
        # Check Jenkins service
        echo "🔧 Jenkins service status:"
        sudo systemctl status jenkins --no-pager -l || echo "Jenkins service check failed"
        echo ""
        
        # Check Jenkins web interface
        echo "🌐 Jenkins web interface:"
        curl -s -I http://localhost:8080/login | head -1 || echo "Jenkins web interface not accessible"
        echo ""
        
        # Check SonarQube
        echo "🔍 SonarQube status:"
        curl -s http://localhost:9000/api/system/status || echo "SonarQube not accessible"
        echo ""
        
        # Check Docker containers
        echo "🐳 Docker containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "Docker not accessible"
        echo ""
        
        # Check system resources
        echo "💻 System resources:"
        echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
        echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
        echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
        echo ""
        
        echo "✅ Status check completed on EC2"
EOF
}

# Function to run comprehensive pipeline test on EC2
run_comprehensive_pipeline_test() {
    local instance_ip=$1
    
    echo "🧪 Running comprehensive pipeline test on EC2..."
    
    ssh -i "$KEY_PATH" "$EC2_USER@$instance_ip" << 'EOF'
        echo "=== Comprehensive DevSecOps Pipeline Test ==="
        
        cd ~/ci-cd-project-3/scripts
        
        # Run the comprehensive pipeline test
        if [ -f "test-comprehensive-pipeline.sh" ]; then
            echo "🚀 Executing comprehensive pipeline test..."
            ./test-comprehensive-pipeline.sh
        else
            echo "❌ test-comprehensive-pipeline.sh not found"
            
            # Manual pipeline trigger as fallback
            echo "🔄 Attempting manual pipeline trigger..."
            
            JENKINS_URL="http://localhost:8080"
            JENKINS_USER="admin"
            
            if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
                JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
                echo "✅ Retrieved Jenkins password"
                
                # List existing jobs
                echo "📋 Existing Jenkins jobs:"
                curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
                    "$JENKINS_URL/api/json?tree=jobs[name,color]" | \
                    python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for job in data.get('jobs', []):
        print(f'  - {job.get(\"name\", \"Unknown\")}: {job.get(\"color\", \"unknown\")}')
except:
    print('  Error parsing job list')
"
                
                # Try to trigger DevSecOps-Pipeline
                echo "🔨 Triggering DevSecOps-Pipeline..."
                curl -s -X POST -u "$JENKINS_USER:$JENKINS_PASSWORD" \
                    "$JENKINS_URL/job/DevSecOps-Pipeline/build" && \
                    echo "✅ Pipeline triggered" || echo "❌ Pipeline trigger failed"
                
            else
                echo "❌ Jenkins password not accessible"
            fi
        fi
        
        echo "✅ Pipeline test completed on EC2"
EOF
}

# Function to check pipeline results
check_pipeline_results() {
    local instance_ip=$1
    
    echo "📊 Checking pipeline results on EC2..."
    
    ssh -i "$KEY_PATH" "$EC2_USER@$instance_ip" << 'EOF'
        echo "=== Pipeline Results Check ==="
        
        JENKINS_URL="http://localhost:8080"
        JENKINS_USER="admin"
        
        if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
            JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
            
            # Get latest build info for DevSecOps-Pipeline
            echo "📈 Latest DevSecOps-Pipeline build:"
            curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
                "$JENKINS_URL/job/DevSecOps-Pipeline/api/json?tree=lastBuild[number,result,timestamp,duration]" | \
                python3 -c "
import sys, json
from datetime import datetime

try:
    data = json.load(sys.stdin)
    build = data.get('lastBuild', {})
    
    if build:
        number = build.get('number', 'N/A')
        result = build.get('result', 'N/A')
        timestamp = build.get('timestamp', 0)
        duration = build.get('duration', 0)
        
        if timestamp:
            dt = datetime.fromtimestamp(timestamp/1000)
            time_str = dt.strftime('%Y-%m-%d %H:%M:%S')
        else:
            time_str = 'N/A'
        
        print(f'Build #{number}')
        print(f'Result: {result}')
        print(f'Time: {time_str}')
        print(f'Duration: {duration/1000:.1f}s')
        print(f'URL: $JENKINS_URL/job/DevSecOps-Pipeline/{number}/')
    else:
        print('No builds found')
        
except Exception as e:
    print(f'Error: {e}')
"
            
            echo ""
            echo "📋 Recent console output (last 30 lines):"
            curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
                "$JENKINS_URL/job/DevSecOps-Pipeline/lastBuild/consoleText" | tail -30
                
        else
            echo "❌ Cannot access Jenkins credentials"
        fi
        
        echo ""
        echo "✅ Results check completed"
EOF
}

# Main execution
main() {
    echo "=== DevSecOps Pipeline EC2 Execution ==="
    echo "Time: $(date)"
    echo ""
    
    # Get EC2 instance IP
    local instance_ip
    if ! instance_ip=$(get_ec2_instance_ip); then
        exit 1
    fi
    
    echo ""
    
    # Check SSH connection
    if ! check_ssh_connection "$instance_ip"; then
        exit 1
    fi
    
    echo ""
    
    # Upload scripts
    upload_scripts "$instance_ip"
    echo ""
    
    # Run Jenkins status check
    run_jenkins_status_check "$instance_ip"
    echo ""
    
    # Run comprehensive pipeline test
    run_comprehensive_pipeline_test "$instance_ip"
    echo ""
    
    # Check results
    check_pipeline_results "$instance_ip"
    echo ""
    
    echo "🎉 DevSecOps pipeline execution on EC2 completed!"
    echo "🌐 Jenkins URL: http://$instance_ip:8080"
    echo "🔍 SonarQube URL: http://$instance_ip:9000"
    echo ""
    echo "💡 To access Jenkins directly:"
    echo "   ssh -i $KEY_PATH $EC2_USER@$instance_ip"
}

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI."
    exit 1
fi

if [ ! -f "$KEY_PATH" ]; then
    echo "❌ SSH key not found at $KEY_PATH"
    echo "💡 Please update KEY_PATH variable or ensure SSH key exists"
    exit 1
fi

# Run main function
main "$@"
