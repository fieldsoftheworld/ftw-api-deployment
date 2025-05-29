variable "environment" {
  description = "Deployment Environment"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "fastapi_app_port" {
  description = "Port that the FastAPI application runs on"
  type        = number
  default     = 8000

  validation {
    condition = var.fastapi_app_port >= 1024 && var.fastapi_app_port <= 65535
    error_message = "FastAPI port must be between 1024 and 65535."
  }
}

variable "enable_vpc_endpoints_sg" {
  description = "Create security group for VPC endpoints"
  type        = bool
  default     = true
}
