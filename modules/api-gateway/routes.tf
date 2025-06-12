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

  # Request transformation - pass the original path to ALB
  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}
# API GATEWAY ROUTES
# Route for GET /
resource "aws_apigatewayv2_route" "root_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# Route for PUT /example - Compute field boundaries and return GeoJSON
resource "aws_apigatewayv2_route" "example_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "PUT /example"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# Route for GET /health - Health check endpoint
resource "aws_apigatewayv2_route" "health_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

