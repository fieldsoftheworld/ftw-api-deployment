terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# DYNAMODB TABLE FOR PROJECT MANAGEMENT

resource "aws_dynamodb_table" "ftw_inference_api_table" {
  name           = "${var.environment}-ftw-inference-api-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = "project_id"

  attribute {
    name = "project_id"
    type = "S"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-ftw-inference-api-table"
      Environment = var.environment
      Purpose     = "project-state-management"
    }
  )
}

# VPC ENDPOINT FOR DYNAMODB ACCESS

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  # Policy to allow access to our specific table
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          aws_dynamodb_table.ftw_inference_api_table.arn,
          "${aws_dynamodb_table.ftw_inference_api_table.arn}/*"
        ]
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-dynamodb-vpc-endpoint"
      Environment = var.environment
      Purpose     = "private-dynamodb-access"
    }
  )
}

# DATA SOURCES


data "aws_region" "current" {}

