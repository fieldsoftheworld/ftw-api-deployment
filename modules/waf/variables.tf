variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "rate_limit" {
  description = "Rate limit for requests per 5-minute period"
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Tags to apply to WAF resources"
  type        = map(string)
  default     = {}
}