# ALB Integration for API Gateway


# Integration to ALB for all routes via VPC Link
resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = var.alb_listener_arn

  # Connection settings - use VPC Link for internal ALB
  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.main.id

  # Timeout settings (max 30 seconds for API Gateway)
  timeout_milliseconds = 29000

  # Request transformation - prepend stage name to all paths for FastAPI
  request_parameters = {
    "overwrite:path" = "/${var.stage_name}$request.path"
  }
}
# API GATEWAY ROUTES
resource "aws_apigatewayv2_route" "api_routes" {
  for_each = var.api_routes

  api_id    = aws_apigatewayv2_api.main.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"

  # Authorization logic - same for all routes, defined once
  authorization_type = var.enable_cloudfront_protection ? "CUSTOM" : "NONE"
  authorizer_id      = var.enable_cloudfront_protection ? aws_apigatewayv2_authorizer.cloudfront_authorizer.id : null
}

