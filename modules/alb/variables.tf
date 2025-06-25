# Required variables
variable "environment" {
  description = "Deployment Environment"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_security_group_ids" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
}

variable "custom_domain_name" {
  description = "Custom domain name (empty string if no custom domain)"
  type        = string
  default     = ""
}

# Common configuration with sensible defaults
variable "fastapi_port" {
  description = "Port on which FastAPI application runs"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
  default     = "/health"
}

# Single object variable for all other configuration
variable "alb_config" {
  description = "ALB configuration settings"
  type = object({
    enable_deletion_protection       = optional(bool, false)
    access_logs_bucket               = optional(string, "")
    deregistration_delay             = optional(number, 30)
    slow_start_duration              = optional(number, 30)
    health_check_interval            = optional(number, 30)
    health_check_timeout             = optional(number, 5)
    health_check_healthy_threshold   = optional(number, 2)
    health_check_unhealthy_threshold = optional(number, 2)
    health_check_matcher             = optional(string, "200")
    enable_stickiness                = optional(bool, false)
    stickiness_duration              = optional(number, 86400)
    ssl_policy                       = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
  })
  default = {}
}