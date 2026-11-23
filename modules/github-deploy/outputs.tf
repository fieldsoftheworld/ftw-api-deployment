output "deploy_role_arn" {
  description = "IAM role ARN for the deploy workflow. Set it as the GitHub repo variable AWS_DEPLOY_ROLE_ARN."
  value       = aws_iam_role.deploy.arn
}

output "deploy_document_name" {
  description = "Name of the SSM Command document the workflow runs."
  value       = aws_ssm_document.deploy.name
}

output "deployed_sha_parameter_name" {
  description = "SSM parameter holding the last deployed SHA."
  value       = aws_ssm_parameter.deployed_sha.name
}

output "deployed_sha_parameter_arn" {
  description = "ARN of the deployed SHA parameter (granted read access to the instance role)."
  value       = aws_ssm_parameter.deployed_sha.arn
}

output "deploy_log_group_name" {
  description = "CloudWatch log group for deploy command output."
  value       = aws_cloudwatch_log_group.deploy.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider (created or looked up)."
  value       = local.oidc_provider_arn
}
