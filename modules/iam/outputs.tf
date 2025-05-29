# EC2 Role Outputs
output "ec2_fastapi_role_arn" {
  description = "The ARN of the EC2 FastAPI IAM role"
  value       = aws_iam_role.ec2_fastapi_app_role.arn
}

output "ec2_fastapi_role_name" {
  description = "The name of the EC2 FastAPI IAM role"
  value       = aws_iam_role.ec2_fastapi_app_role.name
}

output "ec2_fastapi_instance_profile_arn" {
  description = "The ARN of the EC2 FastAPI instance profile"
  value       = aws_iam_instance_profile.ec2_fastapi_app_profile.arn
}

output "ec2_fastapi_instance_profile_name" {
  description = "The name of the EC2 FastAPI instance profile"
  value       = aws_iam_instance_profile.ec2_fastapi_app_profile.name
}

# API Gateway Role Outputs
output "api_gateway_role_arn" {
  description = "The ARN of the API Gateway IAM role"
  value       = aws_iam_role.api_gateway_role.arn
}

output "api_gateway_role_name" {
  description = "The name of the API Gateway IAM role"
  value       = aws_iam_role.api_gateway_role.name
}

# Policy Information
output "policies_attached" {
  description = "List of policies and features enabled for the EC2 role"
  value = {
    cloudwatch_logs        = true
    s3_access             = true
  }
}

# S3 Access Information
output "s3_bucket_arn" {
  description = "The S3 bucket ARN that the EC2 role has access to"
  value       = var.s3_bucket_arn
}