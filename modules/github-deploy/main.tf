data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  oidc_url      = "https://token.actions.githubusercontent.com"
  oidc_host     = "token.actions.githubusercontent.com"
  document_name = "ftw-${var.environment}-deploy-api"
  parameter     = "/ftw/${var.environment}/api/deployed-sha"
  log_group     = "/ftw/${var.environment}/deploy"
  account_id    = data.aws_caller_identity.current.account_id
  region        = data.aws_region.current.name

  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn

  common_tags = merge(var.tags, {
    Environment = var.environment
    Purpose     = "github-actions-deploy"
  })
}

################################################################################
# GitHub Actions OIDC provider (one per account)
################################################################################

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = local.oidc_url
  client_id_list = ["sts.amazonaws.com"]

  tags = merge(local.common_tags, { Name = "github-actions-oidc" })
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = local.oidc_url
}

################################################################################
# Deploy role assumed by the ftw-inference-api deploy workflow
################################################################################

resource "aws_iam_role" "deploy" {
  name = "${var.environment}-ftw-inference-api-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRoleWithWebIdentity"
        Principal = { Federated = local.oidc_provider_arn }
        Condition = {
          StringEquals = {
            "${local.oidc_host}:aud" = "sts.amazonaws.com"
            "${local.oidc_host}:sub" = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "${var.environment}-ftw-inference-api-deploy" })
}

resource "aws_iam_role_policy" "deploy" {
  name = "${var.environment}-ftw-inference-api-deploy"
  role = aws_iam_role.deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "RunDeployDocument"
        Effect   = "Allow"
        Action   = "ssm:SendCommand"
        Resource = aws_ssm_document.deploy.arn
      },
      {
        # ssm:resourceTag/<key> is the SSM-specific key for the target instance's tags
        # (Service Authorization Reference, SendCommand / instance resource).
        Sid      = "OnTaggedApiInstancesOnly"
        Effect   = "Allow"
        Action   = "ssm:SendCommand"
        Resource = "arn:aws:ec2:${local.region}:${local.account_id}:instance/*"
        Condition = {
          StringEquals = {
            "ssm:resourceTag/Purpose"     = var.target_purpose_tag
            "ssm:resourceTag/Environment" = var.environment
          }
        }
      },
      {
        Sid    = "TrackCommands"
        Effect = "Allow"
        Action = [
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations",
          "ssm:ListCommands",
          "ec2:DescribeInstances",
        ]
        Resource = "*"
      },
      {
        Sid      = "RecordDeployedSha"
        Effect   = "Allow"
        Action   = ["ssm:PutParameter", "ssm:GetParameter"]
        Resource = aws_ssm_parameter.deployed_sha.arn
      },
    ]
  })
}

################################################################################
# SSM Command document: check out a SHA and run scripts/update.sh
################################################################################

resource "aws_ssm_document" "deploy" {
  name            = local.document_name
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Deploy ftw-inference-api at an exact commit SHA and restart the service."
    parameters = {
      sha = {
        type           = "String"
        description    = "Full 40-character commit SHA on ${var.github_branch} to deploy."
        allowedPattern = "^[0-9a-f]{40}$"
      }
    }
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "deploy"
        inputs = {
          timeoutSeconds = tostring(var.command_timeout_seconds)
          runCommand = [
            # aws:runShellScript runs under /bin/sh (dash), so no pipefail.
            "set -eu",
            # Checkout happens here, not in update.sh, so the update.sh that runs is the one at the target SHA.
            "sudo -u ubuntu -i bash -lc 'cd ~/ftw-inference-api && git fetch --prune origin && git checkout --force {{ sha }} && ./scripts/update.sh'",
          ]
        }
      }
    ]
  })

  tags = merge(local.common_tags, { Name = local.document_name })
}

################################################################################
# Deployed SHA (written by the workflow, read by user-data at boot)
################################################################################

resource "aws_ssm_parameter" "deployed_sha" {
  name        = local.parameter
  description = "Commit SHA of ftw-inference-api last deployed by GitHub Actions. New instances boot this ref."
  type        = "String"
  value       = "main"

  # The deploy workflow owns the value after creation.
  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(local.common_tags, { Name = local.parameter })
}

################################################################################
# Deploy command output
################################################################################

resource "aws_cloudwatch_log_group" "deploy" {
  name              = local.log_group
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, { Name = local.log_group })
}
