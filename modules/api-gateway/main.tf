terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create HTTP API (API Gateway v2)
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.environment}-${var.api_name}"
  protocol_type = "HTTP"
  description   = "HTTP API for ${var.environment} FastAPI application"

  # CORS configuration with smart defaults
  cors_configuration {
    allow_credentials = var.api_config.cors_allow_credentials
    allow_headers     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
    allow_methods     = ["GET", "POST"]
    allow_origins     = var.api_config.cors_allow_origins
    expose_headers    = []
    max_age           = var.api_config.cors_max_age
  }

  tags = {
    Name        = "${var.environment}-http-api"
    Environment = var.environment
    Type        = "HTTP-API"
  }
}

# Create CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.environment}-${var.api_name}"
  retention_in_days = var.api_config.log_retention_days

  tags = {
    Name        = "${var.environment}-api-gateway-logs"
    Environment = var.environment
  }
}

# Create a stage for the API
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.stage_name
  auto_deploy = var.api_config.auto_deploy

  # Enable detailed logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      error            = "$context.error.message"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  # Enable detailed metrics
  default_route_settings {
    detailed_metrics_enabled = var.api_config.detailed_metrics_enabled
    throttling_burst_limit   = var.api_config.throttling_burst_limit
    throttling_rate_limit    = var.api_config.throttling_rate_limit
  }

  tags = {
    Name        = "${var.environment}-${var.stage_name}"
    Environment = var.environment
  }
}
