#!/bin/bash

# Script to check DevSecOps setup status and validate tools once complete

SERVER_IP="34.255.139.128"
SSH_KEY="~/Downloads/opsworx-ie.pem"

echo "Checking DevSecOps setup status..."

# Check if setup is complete
ssh -i $SSH_KEY -o StrictHostKeyChecking=no ec2-user@$SERVER_IP "
if [ -f /home/ec2-user/devsecops-setup-complete.txt ]; then
    echo '✅ Setup completed!'
    cat /home/ec2-user/devsecops-setup-complete.txt
    echo ''
    echo '🔍 Running service validation...'
    /home/ec2-user/monitor-services.sh
else
    echo '⏳ Setup still in progress...'
    echo 'Latest setup log entries:'
    tail -10 /var/log/devsecops-setup.log 2>/dev/null || echo 'Log not available yet'
fi
"

echo ""
echo "Service URLs (once setup is complete):"
echo "Jenkins: http://$SERVER_IP:8080"
echo "SonarQube: http://$SERVER_IP:9000"
echo "SSH: ssh -i $SSH_KEY ec2-user@$SERVER_IP"
