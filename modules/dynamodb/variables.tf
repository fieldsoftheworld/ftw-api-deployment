variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where DynamoDB VPC endpoint will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for VPC endpoint"
  type        = list(string)
}

variable "vpc_endpoint_security_group_ids" {
  description = "Security group IDs for VPC endpoint"
  type        = list(string)
}

variable "read_capacity" {
  description = "Read capacity units for DynamoDB table"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units for DynamoDB table"
  type        = number
  default     = 5
}

variable "gsi_read_capacity" {
  description = "Read capacity units for Global Secondary Indexes"
  type        = number
  default     = 5
}

variable "gsi_write_capacity" {
  description = "Write capacity units for Global Secondary Indexes"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags to apply to DynamoDB resources"
  type        = map(string)
  default     = {}
}

variable "route_table_ids" {
  description = "List of route table IDs for DynamoDB Gateway VPC endpoint"
  type        = list(string)
}