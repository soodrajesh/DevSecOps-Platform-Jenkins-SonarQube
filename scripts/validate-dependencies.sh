#!/bin/bash

# Dependency validation script for CI/CD pipeline
# This script validates all required tools and configurations

set -e

echo "=== Dependency Validation Script ==="
echo "Validating CI/CD pipeline dependencies..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check version
check_version() {
    local tool=$1
    local version_cmd=$2
    echo "Checking $tool version..."
    eval $version_cmd
}

# Validate Terraform
if command_exists terraform; then
    check_version "Terraform" "terraform version"
    
    # Check minimum version (>= 1.0)
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    echo "Terraform version: $TERRAFORM_VERSION"
else
    echo "ERROR: Terraform is not installed"
    exit 1
fi

# Validate AWS CLI
if command_exists aws; then
    check_version "AWS CLI" "aws --version"
    
    # Check AWS profile
    echo "Validating AWS profile 'raj-private'..."
    if aws configure list-profiles | grep -q "raj-private"; then
        echo "[OK] AWS profile 'raj-private' found"
        
        # Test AWS credentials
        echo "Testing AWS credentials..."
        aws sts get-caller-identity --profile raj-private
        echo "[OK] AWS credentials validated"
    else
        echo "ERROR: AWS profile 'raj-private' not found"
        echo "Available profiles:"
        aws configure list-profiles
        exit 1
    fi
else
    echo "ERROR: AWS CLI is not installed"
    exit 1
fi

# Validate Python and pip
if command_exists python3; then
    check_version "Python" "python3 --version"
else
    echo "ERROR: Python3 is not installed"
    exit 1
fi

if command_exists pip3; then
    check_version "pip" "pip3 --version"
else
    echo "ERROR: pip3 is not installed"
    exit 1
fi

# Validate jq (for JSON parsing)
if command_exists jq; then
    check_version "jq" "jq --version"
else
    echo "WARNING: jq is not installed (recommended for JSON parsing)"
fi

# Validate Git
if command_exists git; then
    check_version "Git" "git --version"
else
    echo "ERROR: Git is not installed"
    exit 1
fi

# Check if we're in a Git repository
if [ -d ".git" ]; then
    echo "[OK] Running in a Git repository"
else
    echo "WARNING: Not in a Git repository"
fi

# Validate Terraform configuration
echo "Validating Terraform configuration..."
if [ -f "main.tf" ]; then
    echo "[OK] main.tf found"
    terraform fmt -check=true -diff=true
    terraform validate
    echo "[OK] Terraform configuration is valid"
else
    echo "ERROR: main.tf not found"
    exit 1
fi

# Check required files
REQUIRED_FILES=("backend.tf" "vars.tf" "providers.tf" "app1-install.sh")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "[OK] $file found"
    else
        echo "ERROR: Required file $file not found"
        exit 1
    fi
done

echo ""
echo "=== All Dependencies Validated Successfully ==="
echo "Pipeline is ready to execute!"
