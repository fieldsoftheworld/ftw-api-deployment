# Required variables only
variable "environment" {
  description = "Deployment Environment"
  type        = string
}

# Optional with smart defaults
variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "ftw-api"
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "v1"
}

# Single object for all configuration with defaults
variable "api_config" {
  description = "API Gateway configuration settings"
  type = object({
    auto_deploy              = optional(bool, true)
    log_retention_days       = optional(number, 30)
    cors_allow_origins       = optional(list(string), ["*"])
    cors_allow_credentials   = optional(bool, false)
    cors_max_age             = optional(number, 300)
    detailed_metrics_enabled = optional(bool, true)
    throttling_burst_limit   = optional(number, 100)
    throttling_rate_limit    = optional(number, 100)
  })
  default = {}
}