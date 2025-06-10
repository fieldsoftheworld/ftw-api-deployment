# ALB Integration for API Gateway


# Integration to ALB for all routes
resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "http://${var.alb_dns_name}"

  # Connection settings
  connection_type = "INTERNET"

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