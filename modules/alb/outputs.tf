output "alb_id" {
  description = "The ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

# Target Group outputs
output "target_group_arn" {
  description = "The ARN of the FastAPI target group"
  value       = aws_lb_target_group.fastapi.arn
}

output "target_group_name" {
  description = "The name of the FastAPI target group"
  value       = aws_lb_target_group.fastapi.name
}

output "target_group_id" {
  description = "The ID of the FastAPI target group"
  value       = aws_lb_target_group.fastapi.id
}

# Listener outputs
output "https_listener_arn" {
  description = "The ARN of the HTTPS listener (empty if no certificate)"
  value       = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : ""
}

output "http_listener_arn" {
  description = "The ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

# Health check configuration
output "health_check_path" {
  description = "The health check path used by the target group"
  value       = var.health_check_path
}