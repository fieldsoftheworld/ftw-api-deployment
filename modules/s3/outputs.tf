output "output_bucket_id" {
  description = "The name of the model output s3 bucket"
  value       = aws_s3_bucket.ftw_api_model_outputs.id
}

output "output_bucket_arn" {
  description = "The ARN of the model output s3 bucket"
  value       = aws_s3_bucket.ftw_api_model_outputs.arn
}

output "output_bucket_domain_name" {
  description = "The domain name of the model output s3 bucket"
  value       = aws_s3_bucket.ftw_api_model_outputs.bucket_domain_name
}

output "vpc_endpoint_id" {
  description = "The ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}