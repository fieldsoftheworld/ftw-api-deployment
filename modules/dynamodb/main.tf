terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# DYNAMODB TABLES FOR PROJECT MANAGEMENT

# Projects table - stores project metadata and state
resource "aws_dynamodb_table" "projects" {
  name           = "${var.environment}-ftw-projects"
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = "id"

  attribute {
    name = "id"
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
      Name        = "${var.environment}-ftw-projects"
      Environment = var.environment
      Purpose     = "project-state-management"
    }
  )
}

# Images table - stores image metadata for projects
resource "aws_dynamodb_table" "images" {
  name           = "${var.environment}-ftw-images"
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "project_id"
    type = "S"
  }

  attribute {
    name = "window"
    type = "S"
  }

  # GSI for querying by project_id and window
  global_secondary_index {
    name            = "project-window-index"
    hash_key        = "project_id"
    range_key       = "window"
    read_capacity   = var.gsi_read_capacity
    write_capacity  = var.gsi_write_capacity
    projection_type = "ALL"
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
      Name        = "${var.environment}-ftw-images"
      Environment = var.environment
      Purpose     = "image-metadata-storage"
    }
  )
}

# Inference Results table - stores ML inference outputs
resource "aws_dynamodb_table" "inference_results" {
  name           = "${var.environment}-ftw-inference-results"
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "project_id"
    type = "S"
  }

  attribute {
    name = "result_type"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  # GSI for querying by project_id and result_type
  global_secondary_index {
    name            = "project-type-index"
    hash_key        = "project_id"
    range_key       = "result_type"
    read_capacity   = var.gsi_read_capacity
    write_capacity  = var.gsi_write_capacity
    projection_type = "ALL"
  }

  # GSI for querying latest results by created_at
  global_secondary_index {
    name            = "project-created-index"
    hash_key        = "project_id"
    range_key       = "created_at"
    read_capacity   = var.gsi_read_capacity
    write_capacity  = var.gsi_write_capacity
    projection_type = "ALL"
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
      Name        = "${var.environment}-ftw-inference-results"
      Environment = var.environment
      Purpose     = "inference-results-storage"
    }
  )
}

# VPC ENDPOINT FOR DYNAMODB ACCESS

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  # Policy to allow access to all our tables
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
          aws_dynamodb_table.projects.arn,
          "${aws_dynamodb_table.projects.arn}/*",
          aws_dynamodb_table.images.arn,
          "${aws_dynamodb_table.images.arn}/*",
          aws_dynamodb_table.inference_results.arn,
          "${aws_dynamodb_table.inference_results.arn}/*"
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

