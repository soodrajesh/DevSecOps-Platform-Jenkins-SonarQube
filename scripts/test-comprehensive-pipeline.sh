#!/bin/bash

# Test Comprehensive DevSecOps Pipeline
# This script triggers the comprehensive pipeline and monitors its execution

set -e

JENKINS_URL="http://localhost:8080"
JOB_NAME="DevSecOps-Pipeline"
JENKINS_USER="admin"

echo "🚀 Testing Comprehensive DevSecOps Pipeline..."

# Get Jenkins admin password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    echo "✅ Retrieved Jenkins admin password"
else
    echo "❌ Jenkins admin password not found"
    exit 1
fi

# Function to check if Jenkins is ready
check_jenkins_ready() {
    local max_attempts=30
    local attempt=1
    
    echo "🔍 Checking Jenkins availability..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$JENKINS_URL/login" > /dev/null 2>&1; then
            echo "✅ Jenkins is ready (attempt $attempt)"
            return 0
        fi
        
        echo "⏳ Jenkins not ready yet (attempt $attempt/$max_attempts)..."
        sleep 10
        ((attempt++))
    done
    
    echo "❌ Jenkins not available after $max_attempts attempts"
    return 1
}

# Function to trigger pipeline build
trigger_pipeline() {
    echo "🔨 Triggering comprehensive DevSecOps pipeline..."
    
    local response=$(curl -s -w "%{http_code}" \
        -X POST \
        -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/job/$JOB_NAME/build" \
        -o /tmp/jenkins_trigger_response.txt)
    
    if [ "$response" = "201" ]; then
        echo "✅ Pipeline triggered successfully"
        return 0
    else
        echo "❌ Failed to trigger pipeline (HTTP: $response)"
        cat /tmp/jenkins_trigger_response.txt
        return 1
    fi
}

# Function to get latest build number
get_latest_build() {
    local build_info=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/job/$JOB_NAME/api/json?tree=lastBuild[number]")
    
    echo "$build_info" | grep -o '"number":[0-9]*' | cut -d':' -f2
}

# Function to monitor build status
monitor_build() {
    local build_number=$1
    local max_wait=600  # 10 minutes
    local elapsed=0
    
    echo "📊 Monitoring build #$build_number..."
    
    while [ $elapsed -lt $max_wait ]; do
        local build_info=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
            "$JENKINS_URL/job/$JOB_NAME/$build_number/api/json?tree=building,result,duration")
        
        local is_building=$(echo "$build_info" | grep -o '"building":[^,]*' | cut -d':' -f2)
        local result=$(echo "$build_info" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
        
        if [ "$is_building" = "false" ]; then
            echo "🏁 Build completed with result: $result"
            return 0
        fi
        
        echo "⏳ Build still running... (${elapsed}s elapsed)"
        sleep 30
        elapsed=$((elapsed + 30))
    done
    
    echo "⏰ Build monitoring timeout after ${max_wait}s"
    return 1
}

# Function to show build console output
show_build_output() {
    local build_number=$1
    
    echo "📋 Fetching build console output..."
    
    curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/job/$JOB_NAME/$build_number/consoleText" | tail -50
}

# Function to show build summary
show_build_summary() {
    local build_number=$1
    
    echo "📈 Build Summary for #$build_number:"
    
    local build_info=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/job/$JOB_NAME/$build_number/api/json")
    
    echo "$build_info" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Result: {data.get(\"result\", \"UNKNOWN\")}')
print(f'Duration: {data.get(\"duration\", 0)/1000:.1f}s')
print(f'URL: {data.get(\"url\", \"N/A\")}')
print(f'Timestamp: {data.get(\"timestamp\", \"N/A\")}')
"
}

# Main execution
main() {
    echo "=== DevSecOps Pipeline Test ==="
    
    # Check Jenkins availability
    if ! check_jenkins_ready; then
        exit 1
    fi
    
    # Get build number before triggering
    local build_before=$(get_latest_build)
    echo "📊 Latest build before trigger: #$build_before"
    
    # Trigger the pipeline
    if ! trigger_pipeline; then
        exit 1
    fi
    
    # Wait a moment for build to start
    sleep 5
    
    # Get new build number
    local build_after=$(get_latest_build)
    echo "📊 New build triggered: #$build_after"
    
    # Monitor the build
    if monitor_build "$build_after"; then
        show_build_summary "$build_after"
        echo ""
        echo "📋 Last 50 lines of console output:"
        show_build_output "$build_after"
    else
        echo "❌ Build monitoring failed"
        show_build_output "$build_after"
        exit 1
    fi
    
    echo ""
    echo "🎉 Comprehensive DevSecOps pipeline test completed!"
    echo "🌐 View full results at: $JENKINS_URL/job/$JOB_NAME/$build_after/"
}

# Run main function
main "$@"
