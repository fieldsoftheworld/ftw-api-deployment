terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Route53 hosted zone for custom domain (only created if custom domain is specified)
resource "aws_route53_zone" "main" {
  count = var.ssl_config.custom_domain_name != "" ? 1 : 0
  name  = var.ssl_config.custom_domain_name

  tags = {
    Name        = "${var.environment}-${var.ssl_config.custom_domain_name}-zone"
    Environment = var.environment
    Purpose     = "api-custom-domain"
  }
}

# ACM Certificate for custom domain (only created if custom domain is specified)
resource "aws_acm_certificate" "main" {
  count             = var.ssl_config.custom_domain_name != "" ? 1 : 0
  domain_name       = var.ssl_config.custom_domain_name
  validation_method = "DNS"

  tags = {
    Name        = "${var.environment}-ssl-certificate"
    Environment = var.environment
    Purpose     = "api-ssl"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 records for certificate validation (only if custom domain is specified)
resource "aws_route53_record" "validation" {
  for_each = var.ssl_config.custom_domain_name != "" ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main[0].zone_id
}

# Certificate validation (only if custom domain is specified)
resource "aws_acm_certificate_validation" "main" {
  count                   = var.ssl_config.custom_domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}