terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

################################################################################
# Security Groups for Application Load Balancer
################################################################################
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTPS inbound from internet
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # HTTP inbound from internet (for redirect to HTTPS)
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # HTTP inbound from VPC (for VPC Link)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # HTTPS inbound from VPC (for VPC Link)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow all outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
    Purpose     = "load-balancer"
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Security Groups for EC2 instances
################################################################################
resource "aws_security_group" "ec2_fastapi_app" {
  name_prefix = "${var.environment}-ec2-fastapi-sg"
  description = "Security group for FastAPI application EC2 instances"
  vpc_id      = var.vpc_id

  # FastAPI application port from ALB only
  ingress {
    from_port       = var.fastapi_app_port
    to_port         = var.fastapi_app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # All outbound traffic (for package downloads, API calls, etc.)
  egress {
    description      = "All outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.environment}-ec2-fastapi-sg"
    Environment = var.environment
    Purpose     = "fastapi-app"
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Security Groups for API Gateway VPC Link
################################################################################
resource "aws_security_group" "api_gateway_vpc_link" {
  name_prefix = "${var.environment}-apigw-vpc-link-sg"
  description = "Security group for API Gateway VPC Link"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic to ALB
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow HTTPS traffic to ALB
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  tags = {
    Name        = "${var.environment}-apigw-vpc-link-sg"
    Environment = var.environment
    Purpose     = "api-gateway-vpc-link"
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Security Groups for VPC endpoints
################################################################################
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints_sg ? 1 : 0

  name_prefix = "${var.environment}-vpc-endpoints-"
  vpc_id      = var.vpc_id
  description = "Security group for VPC endpoints"

  # HTTPS from FastAPI instances for AWS service calls
  ingress {
    description     = "HTTPS from FastAPI instances"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_fastapi_app.id]
  }

  # HTTPS outbound (VPC endpoints need to communicate with AWS services)
  egress {
    description = "HTTPS to AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-vpc-endpoints-sg"
    Environment = var.environment
    Purpose     = "vpc-endpoints"
  }

  lifecycle {
    create_before_destroy = true
  }
}