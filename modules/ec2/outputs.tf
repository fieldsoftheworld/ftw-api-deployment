# Auto Scaling Group outputs
output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.fastapi_app.arn
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.fastapi_app.name
}

output "autoscaling_group_id" {
  description = "The ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.fastapi_app.id
}

# Launch Template outputs
output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.fastapi_app.id
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = aws_launch_template.fastapi_app.arn
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = aws_launch_template.fastapi_app.latest_version
}

# AMI information
output "ami_id" {
  description = "The Deep Learning AMI ID used by the launch template"
  value       = data.aws_ami.deep_learning_gpu.id
}

output "ami_name" {
  description = "The name of the Deep Learning AMI used"
  value       = data.aws_ami.deep_learning_gpu.name
}

output "ami_description" {
  description = "The description of the Deep Learning AMI used"
  value       = data.aws_ami.deep_learning_gpu.description
}

# Configuration outputs
output "instance_type" {
  description = "The instance type configured for the ASG"
  value       = var.instance_type
}

output "asg_configuration" {
  description = "Auto Scaling Group configuration details"
  value = {
    min_size                  = var.asg_config.min_size
    max_size                  = var.asg_config.max_size
    desired_capacity          = var.asg_config.desired_capacity
    health_check_type         = var.asg_config.health_check_type
    health_check_grace_period = var.asg_config.health_check_grace_period
  }
}

################################################################################
# EMBEDDINGS INSTANCE OUTPUTS
################################################################################

output "embeddings_instance_id" {
  description = "ID of the embeddings EC2 instance"
  value       = var.enable_embeddings_instance ? aws_instance.embeddings[0].id : null
}

output "embeddings_instance_public_ip" {
  description = "Public IP address of the embeddings instance"
  value       = var.enable_embeddings_instance ? aws_instance.embeddings[0].public_ip : null
}

output "embeddings_elastic_ip" {
  description = "Elastic IP address of the embeddings instance"
  value       = var.enable_embeddings_instance ? aws_eip.embeddings_eip[0].public_ip : null
}

output "embeddings_instance_private_ip" {
  description = "Private IP address of the embeddings instance"
  value       = var.enable_embeddings_instance ? aws_instance.embeddings[0].private_ip : null
}

output "embeddings_key_name" {
  description = "Name of the SSH key pair for embeddings instance"
  value       = var.enable_embeddings_instance ? aws_key_pair.embeddings_key[0].key_name : null
}

output "embeddings_instance_arn" {
  description = "ARN of the embeddings EC2 instance"
  value       = var.enable_embeddings_instance ? aws_instance.embeddings[0].arn : null
}

output "embeddings_ssh_connection" {
  description = "SSH connection string for the embeddings instance"
  value       = var.enable_embeddings_instance ? "ssh -i ~/.ssh/${var.environment}-embeddings-key.pem ubuntu@${aws_eip.embeddings_eip[0].public_ip}" : null
}

output "embeddings_private_key_pem" {
  description = "Private key for SSH access (only if auto-generated)"
  value       = var.enable_embeddings_instance && var.embeddings_public_key == "" ? tls_private_key.embeddings_key[0].private_key_pem : null
  sensitive   = true
}

output "embeddings_private_key_openssh" {
  description = "Private key in OpenSSH format (only if auto-generated)"
  value       = var.enable_embeddings_instance && var.embeddings_public_key == "" ? tls_private_key.embeddings_key[0].private_key_openssh : null
  sensitive   = true
}