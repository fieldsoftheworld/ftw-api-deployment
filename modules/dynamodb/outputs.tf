output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.ftw_inference_api_table.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.ftw_inference_api_table.arn
}

output "dynamodb_table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.ftw_inference_api_table.id
}

output "vpc_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "vpc_endpoint_dns_names" {
  description = "DNS names of the DynamoDB VPC endpoint"
  value       = aws_vpc_endpoint.dynamodb.dns_entry[*].dns_name
}