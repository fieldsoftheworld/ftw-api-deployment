output "api_id" {
  description = "The ID of the API Gateway HTTP API"
  value       = aws_apigatewayv2_api.main.id
}

output "api_arn" {
  description = "The ARN of the API Gateway HTTP API"
  value       = aws_apigatewayv2_api.main.arn
}

output "api_endpoint" {
  description = "The URI of the API"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "stage_id" {
  description = "The ID of the API Gateway stage"
  value       = aws_apigatewayv2_stage.main.id
}

output "stage_arn" {
  description = "The ARN of the API Gateway stage"
  value       = aws_apigatewayv2_stage.main.arn
}

output "stage_invoke_url" {
  description = "The URL to invoke the API"
  value       = aws_apigatewayv2_stage.main.invoke_url
}

output "execution_arn" {
  description = "The execution ARN prefix for Lambda integration"
  value       = aws_apigatewayv2_api.main.execution_arn
}

output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.api_gateway.arn
}