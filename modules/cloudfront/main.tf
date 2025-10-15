
# DATA SOURCES FOR CLOUDFRONT POLICIES


# Managed cache policy for no caching (dynamic content)
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

# Managed cache policy for short-term caching
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# Managed origin request policy for API Gateway (excludes Host header)
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
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
  aliases             = var.custom_domain_name != "" ? [var.custom_domain_name] : []

  # Origin configuration - pointing to API Gateway
  origin {
    domain_name = regex("https://([^/]+)", var.api_gateway_invoke_url)[0]
    origin_id   = "api-gateway-${var.environment}"

    # Points to the API Gateway 
    custom_header {
      name  = "X-CloudFront-Secret"
      value = var.cloudfront_secret_header
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Cache behavior for root endpoint - short caching (5 minutes)
  # Note: Removed conflicting root path behavior that was causing 403s
  # All requests now use default cache behavior with proper API Gateway routing

  # Default cache behavior - for dynamic content (no caching)
  default_cache_behavior {
    target_origin_id           = "api-gateway-${var.environment}"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
    origin_request_policy_id   = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # Managed-AllViewerExceptHostHeader
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c" # Managed-SimpleCORS
  }

  # Geographic restrictions (none for now)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL certificate configuration
  viewer_certificate {
    cloudfront_default_certificate = var.custom_domain_name == ""
    acm_certificate_arn            = var.custom_domain_name != "" ? var.certificate_arn : null
    ssl_support_method             = var.custom_domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.custom_domain_name != "" ? "TLSv1.2_2021" : null
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