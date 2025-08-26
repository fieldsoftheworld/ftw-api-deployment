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
  description = "List of private subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for EC2 instances"
  type        = list(string)
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

# Optional variables with defaults
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]*\\.[0-9]*[a-z]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS instance type format (e.g., t3.micro, g4dn.xlarge, g6.2xlarge)."
  }
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access (optional)"
  type        = string
  default     = ""
}

# Auto Scaling Group configuration object
variable "asg_config" {
  description = "Auto Scaling Group configuration settings"
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

variable "fastapi_app_port" {
  description = "Port number for the FastAPI application"
  type        = number
  default     = 8000
}