variable "environment" {
  description = "Deployment environment (dev, stg, prd, tst). Used in resource names and in the instance tag condition."
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prd", "tst"], var.environment)
    error_message = "Environment must be one of: dev, stg, prd, tst."
  }
}

variable "github_repository" {
  description = "GitHub repository (owner/name) allowed to assume the deploy role via OIDC."
  type        = string
  default     = "fieldsoftheworld/ftw-inference-api"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in the form owner/name."
  }
}

variable "github_branch" {
  description = "Only workflows running on this branch may assume the deploy role (matched exactly on the OIDC sub claim)."
  type        = string
  default     = "main"
}

variable "create_oidc_provider" {
  description = <<-EOT
    Create the account-wide GitHub Actions OIDC provider (token.actions.githubusercontent.com).
    An AWS account can hold only one provider per URL. Set to false if it already exists
    (check with `aws iam list-open-id-connect-providers`); the module then looks it up.
  EOT
  type        = bool
  default     = true
}

variable "target_purpose_tag" {
  description = "Value of the Purpose tag on the API instances. The deploy role may run its document only on instances with this tag and Environment = var.environment."
  type        = string
  default     = "fastapi-app"
}

variable "command_timeout_seconds" {
  description = "Execution timeout for the deploy script on the instance."
  type        = number
  default     = 600

  validation {
    condition     = var.command_timeout_seconds >= 60 && var.command_timeout_seconds <= 3600
    error_message = "command_timeout_seconds must be between 60 and 3600."
  }
}

variable "log_retention_days" {
  description = "Retention for the deploy command output log group. dev: 30 is plenty; prd: consider 90+."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a value CloudWatch Logs accepts."
  }
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
