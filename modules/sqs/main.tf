terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Dead Letter Queue for failed tasks
resource "aws_sqs_queue" "task_dlq" {
  name = "${var.environment}-ftw-task-dlq"

  message_retention_seconds = var.message_retention_period

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-ftw-task-dlq"
      Environment = var.environment
      Purpose     = "failed-task-storage"
    }
  )
}

# Main task queue (replaces asyncio.Queue)
resource "aws_sqs_queue" "task_queue" {
  name = "${var.environment}-ftw-task-queue"

  # Message settings for ML tasks
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention_period
  
  # Long polling for efficiency
  receive_wait_time_seconds = 20

  # Dead letter queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.task_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-ftw-task-queue"
      Environment = var.environment
      Purpose     = "inference-polygonize-tasks"
    }
  )
}

# Queue policy to allow EC2 instances to access
resource "aws_sqs_queue_policy" "task_queue_policy" {
  queue_url = aws_sqs_queue.task_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.task_queue.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Data source for account ID
data "aws_caller_identity" "current" {}