# ==========================================
# LAMBDA EXECUTION ROLE & PERMISSIONS
# ==========================================

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.environment}-${var.api_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-lambda-execution-role"
    Environment = var.environment
    Component   = "api-lambda"
  }
}

# Attach basic execution policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

# ==========================================
# LAMBDA FUNCTION PACKAGING
# ==========================================

# Package the root handler Lambda function
data "archive_file" "root_handler_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_functions/root_handler.py"
  output_path = "${path.module}/lambda_functions/root_handler.zip"
}

# Package the example handler Lambda function
data "archive_file" "example_handler_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_functions/example_handler.py"
  output_path = "${path.module}/lambda_functions/example_handler.zip"
}

# ==========================================
# LAMBDA FUNCTIONS
# ==========================================

# Lambda function for GET / (root endpoint)
resource "aws_lambda_function" "root_handler" {
  function_name = "${var.environment}-${var.api_name}-root"
  role         = aws_iam_role.lambda_execution_role.arn
  handler      = "root_handler.handler"
  runtime      = "python3.9"
  timeout      = 30

  filename         = data.archive_file.root_handler_zip.output_path
  source_code_hash = data.archive_file.root_handler_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      API_NAME    = var.api_name
    }
  }

  tags = {
    Name        = "${var.environment}-root-handler"
    Environment = var.environment
    Component   = "api-lambda"
    Route       = "GET /"
  }
}

# Lambda function for PUT /example
resource "aws_lambda_function" "example_handler" {
  function_name = "${var.environment}-${var.api_name}-example"
  role         = aws_iam_role.lambda_execution_role.arn
  handler      = "example_handler.handler"
  runtime      = "python3.9"
  timeout      = 30

  filename         = data.archive_file.example_handler_zip.output_path
  source_code_hash = data.archive_file.example_handler_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      API_NAME    = var.api_name
    }
  }

  tags = {
    Name        = "${var.environment}-example-handler"
    Environment = var.environment
    Component   = "api-lambda"
    Route       = "PUT /example"
  }
}

# ==========================================
# API GATEWAY INTEGRATIONS
# ==========================================

# Integration for GET / endpoint
resource "aws_apigatewayv2_integration" "root_integration" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.root_handler.invoke_arn

  payload_format_version = "2.0"
}

# Integration for PUT /example endpoint
resource "aws_apigatewayv2_integration" "example_integration" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.example_handler.invoke_arn

  payload_format_version = "2.0"
}

# ==========================================
# API GATEWAY ROUTES
# ==========================================

# Route for GET /
resource "aws_apigatewayv2_route" "root_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.root_integration.id}"
}

# Route for PUT /example
resource "aws_apigatewayv2_route" "example_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "PUT /example"
  target    = "integrations/${aws_apigatewayv2_integration.example_integration.id}"
}

# ==========================================
# LAMBDA PERMISSIONS FOR API GATEWAY
# ==========================================

# Allow API Gateway to invoke the root Lambda function
resource "aws_lambda_permission" "root_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.root_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*"
}

# Allow API Gateway to invoke the example Lambda function
resource "aws_lambda_permission" "example_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*"
}