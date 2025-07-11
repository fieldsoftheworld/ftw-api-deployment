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

# PROJECT MANAGEMENT ROUTES

# Route for POST /projects - Create a new project
resource "aws_apigatewayv2_route" "create_project_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /projects"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# Route for GET /projects - List all projects
resource "aws_apigatewayv2_route" "list_projects_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /projects"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# Route for GET /projects/{project_id} - Get project details
resource "aws_apigatewayv2_route" "get_project_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /projects/{project_id}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# Route for GET /projects/{project_id}/status - Get project status
resource "aws_apigatewayv2_route" "get_project_status_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /projects/{project_id}/status"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# Route for DELETE /projects/{project_id} - Delete project
resource "aws_apigatewayv2_route" "delete_project_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "DELETE /projects/{project_id}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# INFERENCE ROUTES

# Route for PUT /projects/{project_id}/inference - Submit inference request
resource "aws_apigatewayv2_route" "inference_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "PUT /projects/{project_id}/inference"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# POLYGONIZATION ROUTES

# Route for PUT /projects/{project_id}/polygons - Submit polygonization request
resource "aws_apigatewayv2_route" "polygonization_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "PUT /projects/{project_id}/polygons"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

# TASK MANAGEMENT ROUTES

# Route for GET /projects/{project_id}/tasks/{task_id} - Get task status
resource "aws_apigatewayv2_route" "get_task_status_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /projects/{project_id}/tasks/{task_id}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

