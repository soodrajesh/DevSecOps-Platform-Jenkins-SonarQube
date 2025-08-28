#!/bin/bash

# Check Jenkins Status and Pipeline Information
# This script provides comprehensive status of Jenkins and existing pipelines

set -e

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"

echo "Checking Jenkins DevSecOps Platform Status..."

# Get Jenkins admin password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    echo "[OK] Jenkins admin password retrieved"
else
    echo "[ERROR] Jenkins admin password not found"
    exit 1
fi

# Function to check Jenkins service status
check_jenkins_service() {
    echo "[INFO] Checking Jenkins service..."
    
    if systemctl is-active --quiet jenkins; then
        echo "[OK] Jenkins service is running"
    else
        echo "[ERROR] Jenkins service is not running"
        sudo systemctl status jenkins --no-pager -l
    fi
}

# Function to check Jenkins web interface
check_jenkins_web() {
    echo "[INFO] Checking Jenkins web interface..."
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/jenkins_check.html "$JENKINS_URL/login")
    
    if [ "$response" = "200" ]; then
        echo "[OK] Jenkins web interface is accessible"
    else
        echo "[ERROR] Jenkins web interface not accessible (HTTP: $response)"
        return 1
    fi
}

# Function to list all jobs
list_jenkins_jobs() {
    echo "[INFO] Listing Jenkins jobs..."
    
    local jobs=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/api/json?tree=jobs[name,color,lastBuild[number,result,timestamp]]")
    
    echo "$jobs" | python3 -c "
import sys, json
from datetime import datetime

try:
    data = json.load(sys.stdin)
    jobs = data.get('jobs', [])
    
    if not jobs:
        print('No jobs found')
    else:
        print(f'Found {len(jobs)} job(s):')
        print()
        for job in jobs:
            name = job.get('name', 'Unknown')
            color = job.get('color', 'unknown')
            last_build = job.get('lastBuild', {})
            
            print(f'Job: {name}')
            print(f'   Status: {color}')
            
            if last_build:
                build_num = last_build.get('number', 'N/A')
                result = last_build.get('result', 'N/A')
                timestamp = last_build.get('timestamp', 0)
                
                if timestamp:
                    dt = datetime.fromtimestamp(timestamp/1000)
                    time_str = dt.strftime('%Y-%m-%d %H:%M:%S')
                else:
                    time_str = 'N/A'
                
                print(f'   Last Build: #{build_num}')
                print(f'   Result: {result}')
                print(f'   Time: {time_str}')
            else:
                print('   No builds yet')
            print()
            
except Exception as e:
    print(f'Error parsing job data: {e}')
"
}

# Function to check specific pipeline status
check_pipeline_status() {
    local job_name=$1
    
    echo "[INFO] Checking pipeline: $job_name"
    
    local job_info=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/job/$job_name/api/json" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "$job_info" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    
    print(f'[OK] Pipeline found: {data.get(\"displayName\", \"Unknown\")}')
    print(f'   Description: {data.get(\"description\", \"No description\")}')
    print(f'   Buildable: {data.get(\"buildable\", False)}')
    
    last_build = data.get('lastBuild')
    if last_build:
        print(f'   Last Build: #{last_build.get(\"number\", \"N/A\")} - {last_build.get(\"result\", \"IN_PROGRESS\")}')
    else:
        print('   No builds yet')
        
    health = data.get('healthReport', [{}])[0]
    if health:
        print(f'   Health: {health.get(\"description\", \"N/A\")} ({health.get(\"score\", 0)}/100)')
    
except Exception as e:
    print(f'Error parsing pipeline data: {e}')
"
    else
        echo "[ERROR] Pipeline '$job_name' not found"
    fi
}

# Function to check SonarQube status
check_sonarqube_status() {
    echo "[INFO] Checking SonarQube status..."
    
    local sonar_response=$(curl -s -w "%{http_code}" -o /tmp/sonar_check.json "http://localhost:9000/api/system/status")
    
    if [ "$sonar_response" = "200" ]; then
        echo "[OK] SonarQube is accessible"
        
        local status=$(cat /tmp/sonar_check.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('status', 'UNKNOWN').upper())
")
        echo "   Status: $status"
    else
        echo "[ERROR] SonarQube not accessible (HTTP: $sonar_response)"
    fi
}

# Function to check Docker status
check_docker_status() {
    echo "[INFO] Checking Docker status..."
    
    if docker ps &>/dev/null; then
        echo "[OK] Docker daemon is accessible"
    else
        echo "[ERROR] Cannot connect to Docker daemon"
        return 1
    fi
    
    if docker ps --filter "name=sonarqube" | grep -q sonarqube; then
        echo "[OK] SonarQube container is running"
    else
        echo "[ERROR] SonarQube container is not running"
    fi
}

# Function to show system resources
show_system_resources() {
    echo "System Resources:"
    echo "   CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "   Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "   Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
}

# Main execution
main() {
    echo "=== Jenkins DevSecOps Platform Status ==="
    echo "Time: $(date)"
    echo ""
    
    # Check Jenkins service
    check_jenkins_service
    echo ""
    
    # Check Jenkins web interface
    if check_jenkins_web; then
        echo ""
        
        # List all jobs
        list_jenkins_jobs
        echo ""
        
        # Check specific pipelines
        check_pipeline_status "DevSecOps-Pipeline"
        echo ""
        check_pipeline_status "DevSecOps-Test"
        echo ""
    fi
    
    # Check SonarQube
    check_sonarqube_status
    echo ""
    
    # Check Docker
    check_docker_status
    echo ""
    
    # Show system resources
    show_system_resources
    echo ""
    
    echo "Status check completed!"
    echo "Jenkins URL: $JENKINS_URL"
    echo "SonarQube URL: http://localhost:9000"
}

# Run main function
main "$@"
