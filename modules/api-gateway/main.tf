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
    allow_methods     = ["GET", "POST", "PUT"]
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

# Custom domain name (only if specified and certificate is provided)
resource "aws_apigatewayv2_domain_name" "main" {
  count       = var.api_config.custom_domain_name != "" && var.api_config.certificate_arn != "" ? 1 : 0
  domain_name = var.api_config.custom_domain_name

  domain_name_configuration {
    certificate_arn = var.api_config.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = {
    Name        = "${var.environment}-api-domain"
    Environment = var.environment
  }
}

# API mapping for custom domain (only if specified and certificate is provided)
resource "aws_apigatewayv2_api_mapping" "main" {
  count       = var.api_config.custom_domain_name != "" && var.api_config.certificate_arn != "" ? 1 : 0
  api_id      = aws_apigatewayv2_api.main.id
  domain_name = aws_apigatewayv2_domain_name.main[0].id
  stage       = aws_apigatewayv2_stage.main.id
}

# VPC Link for connecting API Gateway to internal ALB
resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${var.environment}-vpc-link"
  security_group_ids = var.vpc_link_security_group_ids
  subnet_ids         = var.private_subnet_ids

  tags = {
    Name        = "${var.environment}-vpc-link"
    Environment = var.environment
  }
}
