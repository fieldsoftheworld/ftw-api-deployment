variable "environment" {
  description = "Deployment Environment"
  type        = string
}

variable "ssl_config" {
  description = "SSL certificate configuration"
  type = object({
    custom_domain_name = optional(string, "")
  })
  default = {}

  validation {
    condition = var.ssl_config.custom_domain_name == "" || can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9]*\\.[a-zA-Z]{2,}$", var.ssl_config.custom_domain_name))
    error_message = "Custom domain name must be a valid domain format (e.g., api.example.com) or empty string."
  }
}