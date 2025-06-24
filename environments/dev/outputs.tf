
# CLOUDFRONT AND WAF OUTPUTS


output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.cloudfront_domain_name
}

output "cloudfront_url" {
  description = "Full CloudFront URL (use this as your protected API endpoint)"
  value       = module.cloudfront.cloudfront_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = module.waf.web_acl_arn
}

output "waf_web_acl_name" {
  description = "WAF Web ACL name"
  value       = module.waf.web_acl_name
}


# API PROTECTION SUMMARY


output "api_protection_summary" {
  description = "Summary of API protection setup"
  value = {
    original_api_url    = module.api_gateway.stage_invoke_url
    protected_api_url   = module.cloudfront.cloudfront_url
    waf_enabled         = true
    rate_limit          = "2000 requests per 5 minutes per IP"
    caching_strategy    = "No cache for dynamic content, 5min cache for GET /"
    cost_estimate       = "$8-9/month for CloudFront + WAF"
  }
}