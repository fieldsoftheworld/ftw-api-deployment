variable "environment" {
  description = "Deployment Environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the primary S3 bucket for the FastAPI application"
  type        = string
}

variable "enable_api_gateway_vpc_policy" {
  description = "Enable VPC integration policy for API Gateway"
  type        = bool
  default     = false
}

variable "enable_alb_oidc_auth" {
  description = "Enable OIDC authentication role for ALB"
  type        = bool
  default     = false
}

variable "projects_table_arn" {
  description = "Projects DynamoDB table ARN for EC2 access"
  type        = string
}

variable "images_table_arn" {
  description = "Images DynamoDB table ARN for EC2 access"
  type        = string
}

variable "inference_results_table_arn" {
  description = "Inference Results DynamoDB table ARN for EC2 access"
  type        = string
}
variable "sqs_queue_arn" {
  description = "SQS queue ARN for EC2 access"
  type        = string
}
variable "sqs_dlq_arn" {
  description = "SQS dead letter queue ARN for EC2 access"
  type        = string
}

variable "external_role_arn" {
  description = "ARN of an external IAM role to assume (provided by external account owner)"
  type        = string
  default     = ""
}

variable "external_role_id" {
  description = "External ID required to assume the external role (for additional security)"
  type        = string
  default     = ""
}