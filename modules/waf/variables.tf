variable "environment" {
  description = "Deployment Environment"
  type        = string
  default     = "dev"
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF (requests per 5 minute period per IP)"
  type        = number
  default     = 100
}

variable "allowed_countries" {
  description = "List of allowed countries for WAF geo matching (ISO 3166-1 alpha-2 codes)"
  type        = list(string)
  default     = ["US", "CA", "GB", "DE", "FR", "AU", "JP"] # starting point
}

variable "blocked_ip_addresses" {
  description = "List of blocked IP addresses/CIDR blocks for WAF blocklist"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ip in var.blocked_ip_addresses : can(cidrhost(ip, 0))
    ])
    error_message = "All IP addresses must be valid CIDR notation (e.g., 192.168.1.1/32, 10.0.0.0/16)."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain WAF and other security logs"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be one of the valid CloudWatch retention periods."
  }
}