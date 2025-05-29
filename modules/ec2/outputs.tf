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
  description = "The AMI ID used by the launch template"
  value       = data.aws_ami.amazon_linux.id
}

output "ami_name" {
  description = "The name of the AMI used"
  value       = data.aws_ami.amazon_linux.name
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