output "authorizer_function_arn" {
  description = "ARN of the CloudFront authorizer Lambda function"
  value       = aws_lambda_function.cloudfront_authorizer.arn
}

output "authorizer_function_name" {
  description = "Name of the CloudFront authorizer Lambda function"
  value       = aws_lambda_function.cloudfront_authorizer.function_name
}

output "authorizer_invoke_arn" {
  description = "Invoke ARN for API Gateway authorizer"
  value       = aws_lambda_function.cloudfront_authorizer.invoke_arn
}