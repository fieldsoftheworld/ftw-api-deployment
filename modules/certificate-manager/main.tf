terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# Route53 zone for custom domain (only created if custom domain is specified)

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

# ACM Certificate for CloudFront in us-east-1 (only created if custom domain is specified)
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  count             = var.ssl_config.custom_domain_name != "" ? 1 : 0
  domain_name       = var.ssl_config.custom_domain_name
  validation_method = "DNS"

  tags = {
    Name        = "${var.environment}-cloudfront-ssl-certificate"
    Environment = var.environment
    Purpose     = "cloudfront-ssl"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 records for CloudFront certificate validation (only if custom domain is specified)
resource "aws_route53_record" "cloudfront_validation" {
  for_each = var.ssl_config.custom_domain_name != "" ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => {
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

# CloudFront certificate validation (only if custom domain is specified)
resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  count                   = var.ssl_config.custom_domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.cloudfront[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}