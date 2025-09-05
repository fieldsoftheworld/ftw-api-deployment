output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "api_gateway_id" {
  description = "The ID of the API Gateway HTTP API"
  value       = module.api_gateway.api_id
}

output "api_gateway_endpoint" {
  description = "The endpoint URL of the API Gateway"
  value       = module.api_gateway.api_endpoint
}

output "api_gateway_stage_invoke_url" {
  description = "The invoke URL for the API Gateway stage"
  value       = module.api_gateway.stage_invoke_url
}

output "api_url" {
  description = "The primary API URL (custom domain if configured, otherwise AWS generated)"
  value       = var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : module.api_gateway.stage_invoke_url
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = module.ec2.autoscaling_group_name
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = module.ec2.launch_template_id
}

output "ami_id" {
  description = "The AMI ID used by the EC2 instances"
  value       = module.ec2.ami_id
}