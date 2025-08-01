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
    custom_domain_name       = optional(string, "")
    certificate_arn          = optional(string, "")
  })
  default = {}
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer running FastAPI"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener for VPC Link integration"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for VPC Link"
  type        = list(string)
}

variable "vpc_link_security_group_ids" {
  description = "List of security group IDs for VPC Link"
  type        = list(string)
}
variable "lambda_authorizer_invoke_arn" {
  description = "Lambda authorizer invoke ARN"
  type        = string
  default     = ""
}

variable "lambda_authorizer_function_name" {
  description = "Lambda authorizer function name"
  type        = string
  default     = ""
}

variable "enable_cloudfront_protection" {
  description = "Enable CloudFront secret header protection"
  type        = bool
  default     = false
}
variable "api_routes" {
  description = "Map of API routes to create"
  type = map(object({
    route_key = string
   # methods   = list(string)
  }))
  
  default = {
    "root"                  = { route_key = "GET /", methods = ["GET"] }
    "example"               = { route_key = "PUT /example", methods = ["PUT"] }
    "health"                = { route_key = "GET /health", methods = ["GET"] }
    "create_project"        = { route_key = "POST /projects", methods = ["POST"] }
    "list_projects"         = { route_key = "GET /projects", methods = ["GET"] }
    "get_project"           = { route_key = "GET /projects/{project_id}", methods = ["GET"] }
    "get_project_status"    = { route_key = "GET /projects/{project_id}/status", methods = ["GET"] }
    "delete_project"        = { route_key = "DELETE /projects/{project_id}", methods = ["DELETE"] }
    "inference"             = { route_key = "PUT /projects/{project_id}/inference", methods = ["PUT"] }
    "polygonization"        = { route_key = "PUT /projects/{project_id}/polygons", methods = ["PUT"] }
    "get_task_status"       = { route_key = "GET /projects/{project_id}/tasks/{task_id}", methods = ["GET"] }
  }
}