# Projects Table Outputs
output "projects_table_name" {
  description = "Name of the Projects DynamoDB table"
  value       = aws_dynamodb_table.projects.name
}

output "projects_table_arn" {
  description = "ARN of the Projects DynamoDB table"
  value       = aws_dynamodb_table.projects.arn
}

output "projects_table_id" {
  description = "ID of the Projects DynamoDB table"
  value       = aws_dynamodb_table.projects.id
}

# Images Table Outputs
output "images_table_name" {
  description = "Name of the Images DynamoDB table"
  value       = aws_dynamodb_table.images.name
}

output "images_table_arn" {
  description = "ARN of the Images DynamoDB table"
  value       = aws_dynamodb_table.images.arn
}

output "images_table_id" {
  description = "ID of the Images DynamoDB table"
  value       = aws_dynamodb_table.images.id
}

# Inference Results Table Outputs
output "inference_results_table_name" {
  description = "Name of the Inference Results DynamoDB table"
  value       = aws_dynamodb_table.inference_results.name
}

output "inference_results_table_arn" {
  description = "ARN of the Inference Results DynamoDB table"
  value       = aws_dynamodb_table.inference_results.arn
}

output "inference_results_table_id" {
  description = "ID of the Inference Results DynamoDB table"
  value       = aws_dynamodb_table.inference_results.id
}

output "vpc_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "vpc_endpoint_dns_names" {
  description = "DNS names of the DynamoDB VPC endpoint"
  value       = aws_vpc_endpoint.dynamodb.dns_entry[*].dns_name
}