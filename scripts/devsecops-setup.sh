#!/usr/bin/env bash

# ==============================================================================
# DevSecOps Server Setup Script
# ==============================================================================
# Description: Complete automated setup for Jenkins, SonarQube, and security tools
# Version:     3.0 - Enterprise-Grade with Enhanced Security
# Author:      DevSecOps Team
# License:     MIT
#
# Features:
# - Automated installation of Jenkins, SonarQube, and security tools
# - Comprehensive error handling and logging
# - Security-hardened configurations
# - Idempotent operations (safe to rerun)
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Set shell options for better error handling
shopt -s inherit_errexit
shopt -s nullglob
shopt -s extglob

# Set default umask (restrictive permissions)
umask 0027

# ==============================================================================
# Configuration
# ==============================================================================

# Global variables with readonly where applicable
readonly LOG_FILE="/var/log/devsecops-setup-$(date +%Y%m%d%H%M%S).log"
readonly JENKINS_HOME="/var/lib/jenkins"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# GitHub configuration
readonly GITHUB_REPO="https://github.com/soodrajesh/ci-cd-project-3.git"
readonly GITHUB_BRANCH="test-pipeline-integration"

# AWS Configuration
readonly AWS_REGION="eu-west-1"
readonly AWS_CLI_VERSION="2.13.0"

# Tool versions (pinned for reproducibility)
readonly TERRAFORM_VERSION="1.6.6"
readonly DOCKER_COMPOSE_VERSION="v2.20.3"
readonly NODEJS_VERSION="18.x"
readonly PYTHON_VERSION="3.9"

# Security settings
readonly JENKINS_USER="jenkins"
readonly DEVSEC_USER="devsecops"
readonly TOOLS_DIR="/opt/devsecops-tools"

# ==============================================================================
# Logging and Output Functions
# ==============================================================================

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

# Default log level (can be overridden)
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# ANSI color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging function with log levels
log() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}" > /dev/null
    
    # Color output for console
    case ${level} in
        "DEBUG") [[ ${LOG_LEVEL} -le ${LOG_LEVEL_DEBUG} ]] && echo -e "${BLUE}[DEBUG]${NC} ${message}" ;;
        "INFO")  [[ ${LOG_LEVEL} -le ${LOG_LEVEL_INFO}  ]] && echo -e "${GREEN}[INFO]${NC} ${message}" ;;
        "WARN")  [[ ${LOG_LEVEL} -le ${LOG_LEVEL_WARN}  ]] && echo -e "${YELLOW}[WARN]${NC} ${message}" ;;
        "ERROR") [[ ${LOG_LEVEL} -le ${LOG_LEVEL_ERROR} ]] && echo -e "${RED}[ERROR]${NC} ${message}" ;;
        "FATAL") echo -e "${RED}[FATAL]${NC} ${message}" ; exit 1 ;;
    esac
}

# Helper functions for different log levels
log_debug() { log "DEBUG" "$1"; }
log_info()  { log "INFO" "$1"; }
log_warn()  { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }
log_fatal() { log "FATAL" "$1"; }

# Function to check if running as root
check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        log_fatal "This script must be run as root. Use 'sudo $0'"
    fi
}

# Function to check command availability
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Required command not found: $1"
        return 1
    fi
    return 0
}

# Function to safely create directories with proper permissions
safe_mkdir() {
    local dir_path="$1"
    local mode=${2:-0750}
    local owner=${3:-root:${JENKINS_USER:-root}}
    
    if [[ ! -d "${dir_path}" ]]; then
        mkdir -p "${dir_path}" || log_fatal "Failed to create directory: ${dir_path}"
        chmod "${mode}" "${dir_path}" || log_warn "Failed to set permissions on ${dir_path}"
        chown "${owner}" "${dir_path}" || log_warn "Failed to set ownership on ${dir_path}"
    fi
}

# Function to safely download files with validation
safe_download() {
    local url="$1"
    local output_file="$2"
    local expected_checksum="$3"
    
    log_info "Downloading ${url}..."
    if ! curl -fsSL --retry 3 --retry-delay 5 -o "${output_file}" "${url}"; then
        log_error "Failed to download ${url}"
        return 1
    fi
    
    if [[ -n "${expected_checksum}" ]]; then
        local actual_checksum
        actual_checksum=$(sha256sum "${output_file}" | awk '{print $1}')
        if [[ "${actual_checksum}" != "${expected_checksum}" ]]; then
            log_error "Checksum verification failed for ${output_file}"
            log_error "Expected: ${expected_checksum}"
            log_error "Actual:   ${actual_checksum}"
            return 1
        fi
    fi
    
    return 0
}

# ==============================================================================
# Service Management Functions
# ==============================================================================

# Wait for a service to be available on a specific port
# 
# Args:
#   $1: Service name (for logging)
#   $2: Port number to check
#   $3: (Optional) Maximum wait time in seconds (default: 300)
#   $4: (Optional) Host address (default: localhost)
#
# Returns:
#   0 if service is available, 1 if service is not available after max attempts
wait_for_service() {
    local service="${1:-unknown-service}"
    local port="${2:-80}"
    local max_attempts=${3:-60}  # 5 minutes max with default 5s sleep
    local host="${4:-127.0.0.1}"
    local attempt=1
    
    log_info "Waiting for ${service} to be available at ${host}:${port}..."
    while ! nc -z "${host}" "${port}" >/dev/null 2>&1; do
        if [[ ${attempt} -ge ${max_attempts} ]]; then
            log_error "${service} not available after ${max_attempts} attempts"
            return 1
        fi
        
        log_debug "Waiting for ${service} (attempt ${attempt}/${max_attempts})..."
        sleep 5
        ((attempt++))
    done
    
    log_info "${service} is now available on port ${port}"
    return 0
}

# Enable and start a systemd service with error handling
# 
# Args:
#   $1: Service name
#
# Returns:
#   0 on success, non-zero on failure
enable_and_start_service() {
    local service="$1"
    
    if ! systemctl is-enabled "${service}" >/dev/null 2>&1; then
        log_info "Enabling service: ${service}"
        if ! systemctl enable "${service}"; then
            log_error "Failed to enable service: ${service}"
            return 1
        fi
    fi
    
    if ! systemctl is-active "${service}" >/dev/null 2>&1; then
        log_info "Starting service: ${service}"
        if ! systemctl start "${service}"; then
            log_error "Failed to start service: ${service}"
            systemctl status "${service}" || true
            return 1
        fi
    else
        log_debug "Service already running: ${service}"
    fi
    
    return 0
}

# Restart a systemd service with error handling
# 
# Args:
#   $1: Service name
#
# Returns:
#   0 on success, non-zero on failure
restart_service() {
    local service="$1"
    
    log_info "Restarting service: ${service}"
    if ! systemctl restart "${service}"; then
        log_error "Failed to restart service: ${service}"
        systemctl status "${service}" || true
        return 1
    fi
    
    return 0
}

# ==============================================================================
# System Configuration
# ==============================================================================

# Configure system settings and install base dependencies
configure_system() {
    log_section "Configuring System"
    
    # Update package lists
    log_info "Updating package lists..."
    apt-get update || log_error "Failed to update package lists"
    
    # Install base dependencies
    log_info "Installing base dependencies..."
    local base_packages=(
        "apt-transport-https"
        "ca-certificates"
        "curl"
        "gnupg"
        "lsb-release"
        "software-properties-common"
        "unzip"
        "jq"
        "python3-pip"
        "python3-venv"
        "git"
        "make"
        "gcc"
        "python3-dev"
        "libffi-dev"
        "libssl-dev"
        "net-tools"
        "netcat"
    )
    
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${base_packages[@]}"; then
        log_error "Failed to install base packages"
        return 1
    fi
    
    # Configure system limits for Jenkins and Docker
    log_info "Configuring system limits..."
    local limits_conf="/etc/security/limits.d/99-devsecops.conf"
    cat > "${limits_conf}" << EOF
# Increased limits for Jenkins and Docker
jenkins  soft  nofile  8192
jenkins  hard  nofile  65535
jenkins  soft  nproc   8192
jenkins  hard  nproc   16384
*        soft  nofile  8192
*        hard  nofile  65535
*        soft  nproc   8192
*        hard  nproc   16384
EOF
    
    # Configure sysctl settings
    local sysctl_conf="/etc/sysctl.d/99-devsecops.conf"
    cat > "${sysctl_conf}" << 'EOF'
# Increase system file descriptors
fs.file-max = 2097152

# Increase TCP max buffer size
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# Increase Linux autotuning TCP buffer limits
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Increase the maximum number of connections
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 4096

# Increase the maximum number of file handles
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024

# Increase the maximum number of memory map areas a process may have
vm.max_map_count = 262144

# Enable IP forwarding for Docker
net.ipv4.ip_forward = 1

# Disable IPv6 if not needed
#net.ipv6.conf.all.disable_ipv6 = 1
#net.ipv6.conf.default.disable_ipv6 = 1
#net.ipv6.conf.lo.disable_ipv6 = 1

# Increase the maximum number of open files
fs.nr_open = 1048576

# Increase the maximum number of user processes
kernel.threads-max = 65536

# Increase the maximum number of PIDs
kernel.pid_max = 65536

# Increase the maximum number of user sessions
kernel.pty.max = 12000

# Increase the maximum number of inotify watches
fs.inotify.max_user_watches = 1048576

# Increase the maximum number of inotify instances
fs.inotify.max_user_instances = 1024

# Increase the maximum number of inotify queue events
fs.inotify.max_queued_events = 32768

# Increase the maximum number of file handles
fs.file-max = 2097152

# Increase the maximum number of file descriptors
fs.nr_open = 1048576

# Increase the maximum number of file handles for the system
fs.file-nr = 1048576 0 0

# Increase the maximum number of memory map areas a process may have
vm.max_map_count = 262144
EOF

    # Apply sysctl settings
    if ! sysctl -p "${sysctl_conf}"; then
        log_warn "Failed to apply sysctl settings, but continuing..."
    fi
    
    # Create necessary directories with proper permissions
    safe_mkdir "${TOOLS_DIR}" 0755 root:root
    
    log_info "System configuration completed successfully"
    return 0
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Check if running on a supported Linux distribution
check_distribution() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case ${ID} in
            debian|ubuntu)
                log_info "Detected Debian/Ubuntu Linux distribution"
                return 0
                ;;
            rhel|centos|fedora|amzn)
                log_info "Detected RHEL/CentOS/Fedora/Amazon Linux distribution"
                return 0
                ;;
            *)
                log_warn "Unsupported Linux distribution: ${ID}"
                return 1
                ;;
        esac
    else
        log_error "Could not determine Linux distribution"
        return 1
    fi
}

# Install package using the appropriate package manager
install_packages() {
    local packages=("$@")
    
    if command -v apt-get >/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}" || {
            log_error "Failed to install packages: ${packages[*]}"
            return 1
        }
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "${packages[@]}" || {
            log_error "Failed to install packages: ${packages[*]}"
            return 1
        }
    else
        log_error "No supported package manager found"
        return 1
    fi
    
    return 0
}

# Add a repository if it doesn't exist
add_repository() {
    local repo_name="$1"
    local repo_url="$2"
    local repo_key="$3"
    
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        if [[ ! -f "/etc/apt/sources.list.d/${repo_name}.list" ]]; then
            log_info "Adding repository: ${repo_name}"
            curl -fsSL "${repo_key}" | apt-key add - || {
                log_error "Failed to add repository key: ${repo_name}"
                return 1
            }
            echo "${repo_url}" | tee "/etc/apt/sources.list.d/${repo_name}.list" > /dev/null
            apt-get update || {
                log_error "Failed to update package lists after adding repository: ${repo_name}"
                return 1
            }
        fi
    elif command -v yum >/dev/null 2>&1; then
        # RHEL/CentOS/Fedora
        if ! yum repolist | grep -q "${repo_name}"; then
            log_info "Adding repository: ${repo_name}"
            yum-config-manager --add-repo "${repo_url}" || {
                log_error "Failed to add repository: ${repo_name}"
                return 1
            }
            if [[ -n "${repo_key}" ]]; then
                rpm --import "${repo_key}" || {
                    log_warn "Failed to import repository key: ${repo_name}"
                }
            fi
        fi
    fi
    
    return 0
}

# ==============================================================================
# Main Setup Function
# ==============================================================================

# Main entry point for the DevSecOps server setup
main() {
    local start_time
    start_time=$(date +%s)
    
    log_section "Starting DevSecOps Server Setup"
    log_info "Start time: $(date)"
    log_info "Log file: ${LOG_FILE}"
    
    # Check if running as root
    check_root
    
    # Check Linux distribution
    if ! check_distribution; then
        log_warn "This script is primarily tested on Debian/Ubuntu and RHEL/CentOS systems"
        read -rp "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_fatal "Aborting setup due to unsupported distribution"
        fi
    fi
    
    # Configure system settings
    if ! configure_system; then
        log_error "System configuration failed"
        return 1
    fi
    
    # Install required tools
    if ! install_required_tools; then
        log_error "Failed to install required tools"
        return 1
    fi
    
    # Configure Docker
    if ! configure_docker; then
        log_error "Docker configuration failed"
        return 1
    fi
    
    # Install and configure Jenkins
    if ! install_jenkins; then
        log_error "Jenkins installation failed"
        return 1
    fi
    
    # Install and configure SonarQube
    if ! install_sonarqube; then
        log_error "SonarQube installation failed"
        return 1
    fi
    
    # Install security tools
    if ! install_security_tools; then
        log_error "Security tools installation failed"
        return 1
    fi
    
    # Configure firewall
    if ! configure_firewall; then
        log_warn "Firewall configuration had issues, but continuing..."
    fi
    
    # Final system cleanup
    log_info "Cleaning up temporary files..."
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    
    # Calculate and log setup time
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "DevSecOps server setup completed successfully in ${duration} seconds"
    log_info "Access Jenkins at: http://$(curl -s ifconfig.me):8080"
    log_info "Access SonarQube at: http://$(curl -s ifconfig.me):9000"
    
    return 0
}
# ==============================================================================
# Docker Installation and Configuration
# ==============================================================================

# Install and configure Docker
configure_docker() {
    log_section "Installing and Configuring Docker"
    
    # Install Docker dependencies
    local docker_packages=(
        "docker-ce"
        "docker-ce-cli"
        "containerd.io"
        "docker-compose-plugin"
    )
    
    if ! install_packages "${docker_packages[@]}"; then
        log_error "Failed to install Docker packages"
        return 1
    fi
    
    # Add current user to docker group
    if ! getent group docker >/dev/null; then
        groupadd docker
    fi
    
    usermod -aG docker "${SUDO_USER:-$USER}"
    
    # Configure Docker daemon
    local docker_daemon_config="/etc/docker/daemon.json"
    if [[ ! -f "${docker_daemon_config}" ]]; then
        cat > "${docker_daemon_config}" << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-address-pools": [
    {
      "base": "172.17.0.0/16",
      "size": 24
    }
  ]
}
EOF
    fi
    
    # Enable and start Docker service
    if ! enable_and_start_service docker; then
        log_error "Failed to start Docker service"
        return 1
    fi
    
    # Test Docker installation
    if ! docker run --rm hello-world >/dev/null; then
        log_error "Docker installation test failed"
        return 1
    fi
    
    log_info "Docker installed and configured successfully"
    return 0
}

# ==============================================================================
# Jenkins Installation and Configuration
# ==============================================================================

# Install and configure Jenkins
install_jenkins() {
    log_section "Installing and Configuring Jenkins"
    
    # Install Jenkins dependencies
    local jenkins_deps=(
        "fontconfig"
        "java-17-amazon-corretto"
        "java-17-amazon-corretto-devel"
    )
    
    if ! install_packages "${jenkins_deps[@]}"; then
        log_error "Failed to install Jenkins dependencies"
        return 1
    fi
    
    # Add Jenkins repository
    local jenkins_repo_url="https://pkg.jenkins.io/redhat-stable/jenkins.repo"
    local jenkins_key_url="https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key"
    
    if ! add_repository "jenkins" "${jenkins_repo_url}" "${jenkins_key_url}"; then
        log_error "Failed to add Jenkins repository"
        return 1
    }
    
    # Install Jenkins
    if ! install_packages "jenkins"; then
        log_error "Failed to install Jenkins"
        return 1
    }
    
    # Configure Jenkins
    local jenkins_config="/etc/sysconfig/jenkins"
    if [[ -f "${jenkins_config}" ]]; then
        # Backup original config
        cp "${jenkins_config}" "${jenkins_config}.bak.$(date +%Y%m%d%H%M%S)"
        
        # Update configuration
        sed -i 's/^JENKINS_USER=.*/JENKINS_USER="jenkins"/' "${jenkins_config}"
        sed -i 's/^JENKINS_PORT=.*/JENKINS_PORT="8080"/' "${jenkins_config}"
    fi
    
    # Set proper permissions
    chown -R jenkins:jenkins "/var/lib/jenkins"
    chmod 755 "/var/lib/jenkins"
    
    # Enable and start Jenkins service
    if ! enable_and_start_service jenkins; then
        log_error "Failed to start Jenkins service"
        return 1
    }
    
    # Wait for Jenkins to start
    if ! wait_for_service "Jenkins" 8080; then
        log_error "Jenkins did not start properly"
        return 1
    }
    
    log_info "Jenkins installed and configured successfully"
    log_info "Initial admin password: $(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'Not available')"
    
    return 0
}

# ==============================================================================
# SonarQube Installation and Configuration
# ==============================================================================

# Install and configure SonarQube
install_sonarqube() {
    log_section "Installing and Configuring SonarQube"
    
    # Create SonarQube directories
    local sonar_home="/opt/sonarqube"
    safe_mkdir "${sonar_home}" 0755
    
    # Run SonarQube in Docker
    if ! docker ps -a --format '{{.Names}}' | grep -q '^sonarqube$'; then
        log_info "Starting SonarQube in Docker..."
        docker run -d \
            --name sonarqube \
            --restart unless-stopped \
            -p 9000:9000 \
            -v "${sonar_home}:/opt/sonarqube/data" \
            -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
            sonarqube:lts-community
    else
        log_info "SonarQube container already exists, starting if not running..."
        docker start sonarqube || true
    fi
    
    # Wait for SonarQube to start
    if ! wait_for_service "SonarQube" 9000; then
        log_error "SonarQube did not start properly"
        return 1
    }
    
    log_info "SonarQube installed and configured successfully"
    log_info "Access SonarQube at: http://$(curl -s ifconfig.me):9000"
    log_info "Default credentials: admin/admin"
    
    return 0
}

# ==============================================================================
# Security Tools Installation
# ==============================================================================

# Install security tools
install_security_tools() {
    log_section "Installing Security Tools"
    
    # Install OWASP ZAP
    log_info "Installing OWASP ZAP..."
    local zap_dir="/opt/owasp-zap"
    safe_mkdir "${zap_dir}" 0755
    
    local zap_url="https://github.com/zaproxy/zaproxy/releases/download/v2.14.0/ZAP_2.14.0_Linux.tar.gz"
    local zap_tarball="/tmp/zap.tar.gz"
    
    if ! safe_download "${zap_url}" "${zap_tarball}"; then
        log_error "Failed to download OWASP ZAP"
        return 1
    fi
    
    tar -xzf "${zap_tarball}" -C "${zap_dir}" --strip-components=1
    rm -f "${zap_tarball}"
    
    # Create desktop shortcut
    cat > "/usr/share/applications/owasp-zap.desktop" << 'EOF'
[Desktop Entry]
Name=OWASP ZAP
Comment=The OWASP Zed Attack Proxy
Exec=/opt/owasp-zap/zap.sh
Icon=/opt/owasp-zap/zap.ico
Terminal=false
Type=Application
Categories=Development;Security;
EOF
    
    # Install Trivy
    log_info "Installing Trivy..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
        sh -s -- -b /usr/local/bin v0.50.0
    
    # Install Bandit (Python security linter)
    log_info "Installing Bandit..."
    pip3 install --upgrade bandit
    
    # Install Safety (Python dependency checker)
    log_info "Installing Safety..."
    pip3 install --upgrade safety
    
    # Install Gitleaks (Secrets detection)
    log_info "Installing Gitleaks..."
    local gitleaks_version="v8.18.1"
    local gitleaks_url="https://github.com/gitleaks/gitleaks/releases/download/${gitleaks_version}/gitleaks_${gitleaks_version#v}_linux_x64.tar.gz"
    
    if safe_download "${gitleaks_url}" "/tmp/gitleaks.tar.gz"; then
        tar -xzf "/tmp/gitleaks.tar.gz" -C "/usr/local/bin" gitleaks
        chmod +x "/usr/local/bin/gitleaks"
        rm -f "/tmp/gitleaks.tar.gz"
    else
        log_warn "Failed to install Gitleaks, continuing..."
    fi
    
    log_info "Security tools installed successfully"
    return 0
}

# ==============================================================================
# Firewall Configuration
# ==============================================================================

# Configure system firewall
configure_firewall() {
    log_section "Configuring Firewall"
    
    # Check if firewalld is available
    if ! command -v firewall-cmd >/dev/null 2>&1; then
        log_warn "firewalld not found, skipping firewall configuration"
        return 0
    fi
    
    # Start and enable firewalld
    if ! enable_and_start_service firewalld; then
        log_warn "Failed to start firewalld, skipping firewall configuration"
        return 1
    fi
    
    # Configure default zone
    firewall-cmd --set-default-zone=public --permanent
    
    # Allow SSH
    firewall-cmd --add-service=ssh --permanent
    
    # Allow HTTP/HTTPS
    firewall-cmd --add-service=http --permanent
    firewall-cmd --add-service=https --permanent
    
    # Allow Jenkins
    firewall-cmd --add-port=8080/tcp --permanent
    
    # Allow SonarQube
    firewall-cmd --add-port=9000/tcp --permanent
    
    # Reload firewall rules
    if ! firewall-cmd --reload; then
        log_warn "Failed to reload firewall rules"
        return 1
    fi
    
    log_info "Firewall configured successfully"
    return 0
}

# ==============================================================================
# Required Tools Installation
# ==============================================================================

# Install required tools and dependencies
install_required_tools() {
    log_section "Installing Required Tools"
    
    # Basic development tools
    local dev_tools=(
        "@development"
        "wget"
        "curl"
        "unzip"
        "vim"
        "htop"
        "tree"
        "jq"
        "git"
        "net-tools"
        "python3-pip"
        "python3-devel"
        "gcc"
        "make"
        "openssl-devel"
        "bzip2-devel"
        "libffi-devel"
    )
    
    if ! install_packages "${dev_tools[@]}"; then
        log_error "Failed to install development tools"
        return 1
    fi
    
    # Install Node.js
    if ! command -v node >/dev/null 2>&1; then
        log_info "Installing Node.js..."
        curl -fsSL https://rpm.nodesource.com/setup_18.x | bash - && \
        install_packages "nodejs"
    fi
    
    # Install AWS CLI v2
    if ! command -v aws >/dev/null 2>&1; then
        log_info "Installing AWS CLI v2..."
        local aws_cli_url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
        local aws_cli_zip="/tmp/awscliv2.zip"
        
        if safe_download "${aws_cli_url}" "${aws_cli_zip}"; then
            unzip -q "${aws_cli_zip}" -d "/tmp"
            /tmp/aws/install --update
            rm -rf "/tmp/aws" "${aws_cli_zip}"
        else
            log_warn "Failed to install AWS CLI v2, continuing..."
        fi
    fi
    
    # Install Terraform
    if ! command -v terraform >/dev/null 2>&1; then
        log_info "Installing Terraform..."
        local terraform_version="1.6.6"
        local terraform_url="https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip"
        local terraform_zip="/tmp/terraform.zip"
        
        if safe_download "${terraform_url}" "${terraform_zip}"; then
            unzip -q "${terraform_zip}" -d "/usr/local/bin"
            chmod +x "/usr/local/bin/terraform"
            rm -f "${terraform_zip}"
        else
            log_warn "Failed to install Terraform, continuing..."
        fi
    fi
    
    log_info "Required tools installed successfully"
    return 0
}

# ==============================================================================
# Script Execution
# ==============================================================================

# Only execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Execute main function and capture exit code
    if main; then
        exit 0
    else
        exit 1
    fi
fi
# Set JAVA_HOME globally if not already set
    if ! grep -q 'JAVA_HOME=' /etc/environment; then
        echo 'export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto' >> /etc/environment
        echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/environment
    fi
    
    
    # Configure Jenkins to use Java 17
    mkdir -p /etc/systemd/system/jenkins.service.d
    cat > /etc/systemd/system/jenkins.service.d/java17.conf << EOF
[Service]
Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto"
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
                echo 'DevSecOps Environment Check'
                sh 'echo "Java: $(java -version 2>&1 | head -n1)"'
                sh 'echo "Python: $(python3 --version)"'
                sh 'echo "Docker: $(docker --version)"'
                sh 'echo "AWS CLI: $(aws --version 2>/dev/null || echo Not installed)"'
                echo 'Environment check completed'
            }
        }
        stage('Security Tools Check') {
            steps {
                echo 'Security Tools Verification'
                sh 'which python3 || echo "Python3 not in PATH"'
                sh 'ls -la /home/ec2-user/.local/bin/ 2>/dev/null || echo "No user local bin"'
                echo 'Security tools check completed'
            }
        }
        stage('Success') {
            steps {
                echo 'DevSecOps Test Pipeline Completed Successfully!'
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
echo "Jenkins Status:"
if systemctl is-active --quiet jenkins; then
    echo "  [OK] Service: Running"
    if curl -s -f http://localhost:8080/login > /dev/null; then
        echo "  [OK] Web Interface: Accessible at http://$(hostname -I | awk '{print $1}'):8080"
        if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
            echo "  [PWD] Admin Password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
        fi
    else
        echo "  [ERROR] Web Interface: Not accessible"
    fi
else
    echo "  [ERROR] Service: Not running"
fi
echo ""

# SonarQube Status
echo "SonarQube Status:"
if docker ps --filter "name=sonarqube" --format "{{.Status}}" | grep -q "Up"; then
    echo "  [OK] Container: Running"
    echo "  [WEB] Web Interface: http://$(hostname -I | awk '{print $1}'):9000"
else
    echo "  [ERROR] Container: Not running"
fi
echo ""

# System Resources
echo "System Resources:"
echo "  CPU: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1)%"
echo "  Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "  Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
echo ""

# Security Tools
echo "Security Tools:"
for tool in checkov bandit safety detect-secrets semgrep snyk; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  [OK] $tool: Available"
    else
        echo "  [ERROR] $tool: Not available"
    fi
done
echo ""

echo "Quick Access:"
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
    
    log "DevSecOps platform is ready for use!"
}

# Execute main function
main "$@" 2>&1 | tee -a "$LOG_FILE"
