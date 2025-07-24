terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create internal application load balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = var.alb_security_group_ids
  subnets            = var.private_subnet_ids

  enable_deletion_protection       = var.alb_config.enable_deletion_protection
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  # Enable access logs if bucket is provided
  dynamic "access_logs" {
    for_each = var.alb_config.access_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.alb_config.access_logs_bucket
      prefix  = "alb/${var.environment}"
      enabled = true
    }
  }

  tags = {
    Name        = "${var.environment}-internal-alb"
    Environment = var.environment
    Type        = "internal"
  }
}

# Create target group for FastAPI application
resource "aws_lb_target_group" "fastapi" {
  name     = "${var.environment}-fastapi-tg"
  port     = var.fastapi_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health check configuration with smart defaults
  health_check {
    enabled             = true
    healthy_threshold   = var.alb_config.health_check_healthy_threshold
    unhealthy_threshold = var.alb_config.health_check_unhealthy_threshold
    timeout             = var.alb_config.health_check_timeout
    interval            = var.alb_config.health_check_interval
    path                = "/v1${var.health_check_path}"
    matcher             = var.alb_config.health_check_matcher
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  # Stickiness configuration
  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.alb_config.stickiness_duration
    enabled         = var.alb_config.enable_stickiness
  }

  # Target group attributes
  deregistration_delay = var.alb_config.deregistration_delay
  slow_start           = var.alb_config.slow_start_duration

  target_type = "instance"

  tags = {
    Name        = "${var.environment}-fastapi-target-group"
    Environment = var.environment
  }
}

# Create HTTP listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Always forward to target group (HTTPS termination handled by API Gateway)
  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.fastapi.arn
      }
    }
  }
}