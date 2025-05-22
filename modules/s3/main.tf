terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create model output bucket, vpc endpoint and access control
resource "aws_s3_bucket" "ftw_api_model_outputs" {
  bucket = var.ftw_api_model_outputs_bucket

  tags = {
    Name        = "${var.environment}-ftw-api-model-outputs"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = {
    Name        = "${var.environment}-s3-gateway-endpoint"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "ftw_api_model_outputs" {
  bucket = aws_s3_bucket.ftw_api_model_outputs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

