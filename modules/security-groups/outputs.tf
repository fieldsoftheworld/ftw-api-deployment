output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = "The ARN of the ALB security group"
  value       = aws_security_group.alb.arn
}

# EC2 FastAPI Security Group outputs
output "ec2_fastapi_security_group_id" {
  description = "The ID of the EC2 FastAPI security group"
  value       = aws_security_group.ec2_fastapi_app.id
}

output "ec2_fastapi_security_group_arn" {
  description = "The ARN of the EC2 FastAPI security group"
  value       = aws_security_group.ec2_fastapi_app.arn
}

# API Gateway VPC Link Security Group outputs
output "api_gateway_vpc_link_security_group_id" {
  description = "The ID of the API Gateway VPC Link security group"
  value       = aws_security_group.api_gateway_vpc_link.id
}

output "api_gateway_vpc_link_security_group_arn" {
  description = "The ARN of the API Gateway VPC Link security group"
  value       = aws_security_group.api_gateway_vpc_link.arn
}

# VPC Endpoints Security Group outputs (conditional)
output "vpc_endpoints_security_group_id" {
  description = "The ID of the VPC endpoints security group"
  value       = var.enable_vpc_endpoints_sg ? aws_security_group.vpc_endpoints[0].id : null
}

output "vpc_endpoints_security_group_arn" {
  description = "The ARN of the VPC endpoints security group"
  value       = var.enable_vpc_endpoints_sg ? aws_security_group.vpc_endpoints[0].arn : null
}

# Configuration summary
output "fastapi_app_port" {
  description = "The port configured for the FastAPI application"
  value       = var.fastapi_app_port
}