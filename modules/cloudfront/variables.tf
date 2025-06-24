
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN to associate with CloudFront"
  type        = string
}

variable "tags" {
  description = "Tags to apply to CloudFront resources"
  type        = map(string)
  default     = {}
}