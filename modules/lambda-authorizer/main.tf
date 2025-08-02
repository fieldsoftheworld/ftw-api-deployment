terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Create ZIP file for Lambda function
data "archive_file" "authorizer_zip" {
  type        = "zip"
  source_file = "${path.module}/src/index.py"
  output_path = "${path.module}/authorizer.zip"
}

# IAM role for Lambda function
resource "aws_iam_role" "authorizer_role" {
  name = "${var.environment}-cloudfront-authorizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-cloudfront-authorizer-role"
      Environment = var.environment
    }
  )
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "authorizer_basic" {
  role       = aws_iam_role.authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function for CloudFront secret validation
resource "aws_lambda_function" "cloudfront_authorizer" {
  filename         = data.archive_file.authorizer_zip.output_path
  function_name    = "${var.environment}-cloudfront-authorizer"
  role            = aws_iam_role.authorizer_role.arn
  handler         = "index.lambda_handler"
  runtime         = "python3.13"
  timeout         = 30

  source_code_hash = data.archive_file.authorizer_zip.output_base64sha256

  environment {
    variables = {
      CLOUDFRONT_SECRET = var.cloudfront_secret
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-cloudfront-authorizer"
      Environment = var.environment
      Purpose     = "api-gateway-auth"
    }
  )
}

# CloudWatch log group for Lambda function
resource "aws_cloudwatch_log_group" "authorizer_logs" {
  name              = "/aws/lambda/${aws_lambda_function.cloudfront_authorizer.function_name}"
  retention_in_days = 14

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-cloudfront-authorizer-logs"
      Environment = var.environment
    }
  )
}