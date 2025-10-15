variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "visibility_timeout" {
  description = "Message visibility timeout in seconds (for long-running ML tasks)"
  type        = number
  default     = 900 # 15 minutes for inference/polygonize tasks
}

variable "message_retention_period" {
  description = "How long to keep messages in queue (seconds)"
  type        = number
  default     = 1209600 # 14 days
}

variable "max_receive_count" {
  description = "Max times a message can be received before moving to DLQ"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to SQS resources"
  type        = map(string)
  default     = {}
}