# CIDR blocks for security group restrictions
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the DevSecOps server (set to your IP for production)"
  type        = string
  default     = "0.0.0.0/0" # WARNING: Open to the world for demo. Restrict in production.
}

variable "allowed_jenkins_cidr" {
  description = "CIDR block allowed to access Jenkins web UI (set to your IP for production)"
  type        = string
  default     = "0.0.0.0/0" # WARNING: Open to the world for demo. Restrict in production.
}
