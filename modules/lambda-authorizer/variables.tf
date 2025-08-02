variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cloudfront_secret" {
  description = "Secret value that CloudFront sends to API Gateway"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to Lambda resources"
  type        = map(string)
  default     = {}
}