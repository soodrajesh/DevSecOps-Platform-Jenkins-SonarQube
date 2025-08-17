#!/bin/bash

# Deployment script for CI/CD pipeline
# This script provides a complete deployment workflow with error handling

set -e

# Configuration
AWS_PROFILE="raj-private"
AWS_REGION="eu-west-1"
TERRAFORM_WORKSPACE="development"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Run dependency validation script
    if [ -f "scripts/validate-dependencies.sh" ]; then
        ./scripts/validate-dependencies.sh
    else
        print_error "Dependency validation script not found"
        exit 1
    fi
}

# Function to initialize Terraform
terraform_init() {
    print_status "Initializing Terraform..."
    terraform init -upgrade
}

# Function to select/create workspace
terraform_workspace() {
    print_status "Managing Terraform workspace: $TERRAFORM_WORKSPACE"
    
    # Check if workspace exists
    if terraform workspace list | grep -q "$TERRAFORM_WORKSPACE"; then
        print_status "Workspace '$TERRAFORM_WORKSPACE' exists, selecting..."
        terraform workspace select "$TERRAFORM_WORKSPACE"
    else
        print_status "Creating new workspace '$TERRAFORM_WORKSPACE'..."
        terraform workspace new "$TERRAFORM_WORKSPACE"
    fi
}

# Function to run security scans
security_scans() {
    print_status "Running security scans..."
    
    # Install Checkov if not present
    if ! command -v checkov &> /dev/null; then
        print_status "Installing Checkov..."
        pip3 install checkov
    fi
    
    # Run Checkov scan
    print_status "Running Checkov infrastructure security scan..."
    checkov -d . --compact --skip-check $(cat skip_checks.txt 2>/dev/null || echo "")
}

# Function to plan deployment
terraform_plan() {
    print_status "Creating Terraform plan..."
    terraform plan -out=tfplan -var-file="terraform.tfvars" 2>/dev/null || \
    terraform plan -out=tfplan
}

# Function to apply deployment
terraform_apply() {
    print_status "Applying Terraform changes..."
    terraform apply -auto-approve tfplan
    
    print_status "Deployment completed successfully!"
    terraform output
}

# Function to destroy infrastructure (optional)
terraform_destroy() {
    print_warning "This will destroy all infrastructure!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        print_status "Destroying infrastructure..."
        terraform destroy -auto-approve
    else
        print_status "Destroy cancelled"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  deploy    - Full deployment (default)"
    echo "  plan      - Plan only"
    echo "  destroy   - Destroy infrastructure"
    echo "  validate  - Validate dependencies only"
    echo "  help      - Show this help"
}

# Main execution
main() {
    local action=${1:-deploy}
    
    case $action in
        "deploy")
            check_prerequisites
            terraform_init
            terraform_workspace
            security_scans
            terraform_plan
            terraform_apply
            ;;
        "plan")
            check_prerequisites
            terraform_init
            terraform_workspace
            terraform_plan
            ;;
        "destroy")
            terraform_init
            terraform_workspace
            terraform_destroy
            ;;
        "validate")
            check_prerequisites
            ;;
        "help")
            show_usage
            ;;
        *)
            print_error "Unknown option: $action"
            show_usage
            exit 1
            ;;
    esac
}

# Trap errors
trap 'print_error "Script failed at line $LINENO"' ERR

# Execute main function
main "$@"
