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

# Embeddings Instance Outputs
output "embeddings_instance_id" {
  description = "ID of the embeddings EC2 instance"
  value       = module.ec2.embeddings_instance_id
}

output "embeddings_elastic_ip" {
  description = "Elastic IP address of the embeddings instance"
  value       = module.ec2.embeddings_elastic_ip
}

output "embeddings_ssh_connection" {
  description = "SSH connection command for the embeddings instance"
  value       = module.ec2.embeddings_ssh_connection
}

output "embeddings_instance_status" {
  description = "Status information for embeddings instance"
  value = var.enable_embeddings_instance ? {
    enabled     = true
    instance_id = module.ec2.embeddings_instance_id
    public_ip   = module.ec2.embeddings_elastic_ip
    private_ip  = module.ec2.embeddings_instance_private_ip
    key_name    = module.ec2.embeddings_key_name
  } : {
    enabled = false
    message = "Embeddings instance is not enabled. Set enable_embeddings_instance = true to create it."
  }
}

# Sensitive output for private key
output "embeddings_private_key" {
  description = "Private SSH key for embeddings instance (only if auto-generated - save this securely!)"
  value       = module.ec2.embeddings_private_key_pem
  sensitive   = true
}