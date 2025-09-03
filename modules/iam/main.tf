terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# IAM Role for fastapi instances
resource "aws_iam_role" "ec2_fastapi_app_role" {
  name = "${var.environment}-ec2-fastapi-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-ec2-fastapi-app-role"
    Environment = var.environment
    Purpose     = "fastapi-app"
  }
}

# Attach SSM access policy for EC2
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_fastapi_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent policy for EC2
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ec2_fastapi_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_fastapi_app_profile" {
  name = "${var.environment}-ec2-fastapi-app-profile"
  role = aws_iam_role.ec2_fastapi_app_role.name

  tags = {
    Name        = "${var.environment}-ec2-fastapi-app-profile"
    Environment = var.environment
    Purpose     = "fastapi-app"
  }
}

# Cloudwatch and logging policy for EC2
resource "aws_iam_role_policy" "ec2_cloudwatch_policy" {
  name = "${var.environment}-ec2-cloudwatch-policy"
  role = aws_iam_role.ec2_fastapi_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# Cross-account S3 access role that external accounts can reference in their bucket policies
resource "aws_iam_role" "cross_account_s3_role" {
  count = var.enable_cross_account_s3 ? 1 : 0
  name  = "${var.environment}-cross-account-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_fastapi_app_role.arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-cross-account-s3-role"
    Environment = var.environment
    Purpose     = "cross-account-s3-access"
  }
}

# Policy for the cross-account role to access external S3 buckets
resource "aws_iam_role_policy" "cross_account_s3_policy" {
  count = var.enable_cross_account_s3 ? 1 : 0
  name  = "${var.environment}-cross-account-s3-policy"
  role  = aws_iam_role.cross_account_s3_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObjectVersion",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = concat(
          var.cross_account_s3_bucket_arns,
          [for arn in var.cross_account_s3_bucket_arns : "${arn}/*"]
        )
      }
    ]
  })
}

# Allow EC2 instances to assume external cross-account roles
resource "aws_iam_role_policy" "ec2_assume_external_role" {
  count = var.external_role_arn != "" ? 1 : 0
  name  = "${var.environment}-ec2-assume-external-role"
  role  = aws_iam_role.ec2_fastapi_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = var.external_role_arn
        Condition = var.external_role_id != "" ? {
          StringEquals = {
            "sts:ExternalId" = var.external_role_id
          }
        } : {}
      }
    ]
  })
}

# Allow EC2 instances to assume the cross-account role (for self-managed cross-account access)
resource "aws_iam_role_policy" "ec2_assume_cross_account_role" {
  count = var.enable_cross_account_s3 ? 1 : 0
  name  = "${var.environment}-ec2-assume-cross-account-role"
  role  = aws_iam_role.ec2_fastapi_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.cross_account_s3_role[0].arn
      }
    ]
  })
}

# S3 access policy for EC2
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "${var.environment}-ec2-s3-policy"
  role = aws_iam_role.ec2_fastapi_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObjectVersion",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# DynamoDB access policy for EC2
resource "aws_iam_role_policy" "ec2_dynamodb_policy" {
  name = "${var.environment}-ec2-dynamodb-policy"
  role = aws_iam_role.ec2_fastapi_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
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
          var.projects_table_arn,
          "${var.projects_table_arn}/*",
          var.images_table_arn,
          "${var.images_table_arn}/*",
          var.inference_results_table_arn,
          "${var.inference_results_table_arn}/*"
        ]
      }
    ]
  })
}

# IAM Role for API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.environment}-api-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-api-gateway-role"
    Environment = var.environment
    Purpose     = "api-gateway"
  }
}

# Cloudwatch logs policy for API Gateway
resource "aws_iam_role_policy" "api_gateway_cloudwatch_policy" {
  name = "${var.environment}-api-gateway-cloudwatch-policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# SQS access policy for EC2 (only create if SQS ARN is provided)
resource "aws_iam_role_policy" "ec2_sqs_policy" {

  name = "${var.environment}-ec2-sqs-policy"
  role = aws_iam_role.ec2_fastapi_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          var.sqs_queue_arn,
          var.sqs_dlq_arn
        ]
      }
    ]
  })
}

# Secrets Manager access policy for EC2
resource "aws_iam_role_policy" "ec2_secrets_manager_policy" {
  name = "${var.environment}-ec2-secrets-manager-policy"
  role = aws_iam_role.ec2_fastapi_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}