variable "ftw_api_model_outputs_bucket" {
  description = "Name of the S3 bucket that will store model geotiffs and polygons"
  type        = string
  default     = "ftw-api-model-outputs"
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "region" {
  description = "AWS region to create resources in"
  type        = string
}

variable "route_table_ids" {
  description = "List of route table IDs to associate the S3 endpoint"
  type        = list(string)
}