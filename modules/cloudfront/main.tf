
# DATA SOURCES FOR CLOUDFRONT POLICIES


# Managed cache policy for no caching (dynamic content)
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

# Managed cache policy for short-term caching
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# Managed origin request policy for API Gateway
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

# Managed response headers policy for CORS
data "aws_cloudfront_response_headers_policy" "simple_cors" {
  name = "Managed-SimpleCORS"
}


# CLOUDFRONT DISTRIBUTION FOR API GATEWAY


resource "aws_cloudfront_distribution" "api_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.environment} Fields of the World API"
  default_root_object = ""
  web_acl_id          = var.waf_web_acl_arn

  # Origin configuration - pointing to API Gateway
  origin {
    domain_name = replace(var.api_gateway_invoke_url, "https://", "")
    origin_id   = "api-gateway-${var.environment}"
    origin_path = ""

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Cache behavior for root endpoint - short caching (5 minutes)
  ordered_cache_behavior {
    path_pattern               = "/"
    target_origin_id           = "api-gateway-${var.environment}"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.simple_cors.id

    # Override TTL for short caching
    min_ttl     = 0
    default_ttl = 300  # 5 minutes
    max_ttl     = 300  # 5 minutes
  }

  # Default cache behavior - for dynamic content (no caching)
  default_cache_behavior {
    target_origin_id           = "api-gateway-${var.environment}"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.simple_cors.id
  }

  # Geographic restrictions (none for now)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL certificate configuration
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Tags
  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-api-cloudfront"
      Environment = var.environment
      Module      = "cloudfront"
    }
  )
}