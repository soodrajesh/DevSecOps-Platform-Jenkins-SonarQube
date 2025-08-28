# CIDR blocks for security group restrictions
variable "allowed_sonarqube_cidr" {
  description = "CIDR block allowed to access SonarQube web UI (set to your IP for production)"
  type        = string
  default     = "0.0.0.0/0" # WARNING: Open to the world for demo. Restrict in production.
}

variable "allowed_https_cidr" {
  description = "CIDR block allowed to access HTTPS (set to your IP for production)"
  type        = string
  default     = "0.0.0.0/0" # WARNING: Open to the world for demo. Restrict in production.
}

variable "allowed_http_cidr" {
  description = "CIDR block allowed to access HTTP (set to your IP for production)"
  type        = string
  default     = "0.0.0.0/0" # WARNING: Open to the world for demo. Restrict in production.
}
