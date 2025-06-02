variable "region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-1)."
  }

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1", "eu-north-1",
      "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ap-northeast-2",
      "ap-south-1", "ca-central-1", "sa-east-1"
    ], var.region)
    error_message = "Region must be a valid and commonly used AWS region."
  }
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR notation."
  }

  validation {
    condition     = can(regex("^(10\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.)", var.vpc_cidr_block))
    error_message = "VPC CIDR block must use private IP address ranges (10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16)."
  }

  validation {
    condition     = tonumber(split("/", var.vpc_cidr_block)[1]) >= 16 && tonumber(split("/", var.vpc_cidr_block)[1]) <= 28
    error_message = "VPC CIDR block must have a subnet mask between /16 and /28."
  }
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
  default     = "dev"

  # Restrict environment names to three letter strings and one of dev, stg, prd, or tst
  validation {
    condition     = contains(["dev", "stg", "prd", "tst"], var.environment)
    error_message = "Environment must be one of: dev, stg, prd, tst."
  }

  validation {
    condition     = can(regex("^[a-z]+$", var.environment))
    error_message = "Environment must contain only lowercase letters."
  }
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all private subnets (cost effective) vs one per AZ (high availability)"
  type        = bool
  default     = true
}

variable "ftw_api_model_outputs_bucket" {
  description = "Name of the S3 bucket that will store model geotiffs and polygons"
  type        = string
  default     = "ftw-api-model-outputs-dev"

  validation {
    condition     = !can(regex("\\.", var.ftw_api_model_outputs_bucket))
    error_message = "S3 bucket name must not contain periods (dots) for SSL/TLS compatibility."
  }

  validation {
    condition     = !can(regex("--", var.ftw_api_model_outputs_bucket))
    error_message = "S3 bucket name must not contain consecutive hyphens."
  }

  validation {
    condition     = !can(regex("^xn--|.*-s3alias$", var.ftw_api_model_outputs_bucket))
    error_message = "S3 bucket name must not start with 'xn--' or end with '-s3alias'."
  }
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "ftw-api"
}

variable "api_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "v1"
}

variable "api_auto_deploy" {
  description = "Whether to automatically deploy API changes to the stage"
  type        = bool
  default     = true
}

variable "api_log_retention_days" {
  description = "Number of days to retain API Gateway logs"
  type        = number
  default     = 30
}

variable "api_cors_allow_origins" {
  description = "Origins allowed in CORS requests"
  type        = list(string)
  default     = ["*"]
}

variable "api_detailed_metrics_enabled" {
  description = "Whether to enable detailed CloudWatch metrics for API Gateway"
  type        = bool
  default     = true
}

variable "api_throttling_burst_limit" {
  description = "Throttling burst limit for the API"
  type        = number
  default     = 100
}

variable "api_throttling_rate_limit" {
  description = "Throttling rate limit for the API (requests per second)"
  type        = number
  default     = 100
}

# EC2 and Auto Scaling Group variables
variable "instance_type" {
  description = "EC2 instance type for FastAPI application"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]*\\.[a-z]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS instance type format (e.g., t3.micro, g4dn.xlarge)."
  }
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access (optional, leave empty for no SSH access)"
  type        = string
  default     = ""
}

variable "asg_config" {
  description = "Auto Scaling Group configuration for FastAPI instances"
  type = object({
    min_size                  = optional(number, 1)
    max_size                  = optional(number, 1)
    desired_capacity          = optional(number, 1)
    health_check_type         = optional(string, "EC2")
    health_check_grace_period = optional(number, 300)
  })
  default = {}

  validation {
    condition     = contains(["EC2", "ELB"], var.asg_config.health_check_type)
    error_message = "Health check type must be either 'EC2' or 'ELB'."
  }

  validation {
    condition     = var.asg_config.health_check_grace_period >= 0 && var.asg_config.health_check_grace_period <= 7200
    error_message = "Health check grace period must be between 0 and 7200 seconds."
  }
}

variable "custom_domain_name" {
  description = "Custom domain name for the FastAPI application (optional, leave empty for no custom domain)"
  type        = string
  default     = ""
}