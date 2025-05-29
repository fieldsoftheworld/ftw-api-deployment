terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create WAF for API and apply rules
resource "aws_wafv2_web_acl" "api_protection" {
  name  = "${var.environment}-api-protection-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rule -- core rule set OWASP top 10
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS managed rule -- known bad inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate limit rule
  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"

        scope_down_statement {
          geo_match_statement {
            country_codes = var.allowed_countries
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  # Block IP rule applied only if ips are added
  dynamic "rule" {
    for_each = length(var.blocked_ip_addresses) > 0 ? [1] : []
    content {
      name     = "IPBlocklistRule"
      priority = 4

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.blocked_ips[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "IPBlocklistMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = {
    Name        = "${var.environment}-api-protection-waf"
    Environment = var.environment
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}APIPotectionWAF"
    sampled_requests_enabled   = true
  }
}

# IP set for blocked IPs
resource "aws_wafv2_ip_set" "blocked_ips" {
  count              = length(var.blocked_ip_addresses) > 0 ? 1 : 0
  name               = "${var.environment}-blocked-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_addresses

  tags = {
    Name        = "${var.environment}-blocked-ips"
    Environment = var.environment
  }
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "api_protection" {
  resource_arn            = aws_wafv2_web_acl.api_protection.arn
  log_destination_configs = [aws_cloudwatch_log_group.api_protection.arn]

  redacted_fields {
    single_header {
      name = "Authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "x-api-key"
    }
  }
}

# Cloudwatch Log Group for WAF logs
resource "aws_cloudwatch_log_group" "api_protection" {
  name              = "/aws/wafv2/${var.environment}-api-protection-waf"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-waf-logs"
    Environment = var.environment
  }
}