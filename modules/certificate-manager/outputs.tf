output "certificate_arn" {
  description = "The ARN of the ACM certificate (empty if no custom domain)"
  value       = var.ssl_config.custom_domain_name != "" ? aws_acm_certificate.main[0].arn : ""
}

output "certificate_domain_validation_options" {
  description = "Domain validation options for the certificate"
  value       = var.ssl_config.custom_domain_name != "" ? aws_acm_certificate.main[0].domain_validation_options : []
}

output "route53_zone_id" {
  description = "The Route53 hosted zone ID (empty if no custom domain)"
  value       = var.ssl_config.custom_domain_name != "" ? aws_route53_zone.main[0].zone_id : ""
}

output "custom_domain_name" {
  description = "The custom domain name (empty if not configured)"
  value       = var.ssl_config.custom_domain_name
}

output "has_custom_domain" {
  description = "Whether a custom domain is configured"
  value       = var.ssl_config.custom_domain_name != ""
}

output "route53_name_servers" {
  description = "The Route53 name servers for the hosted zone (empty if no custom domain)"
  value       = var.ssl_config.custom_domain_name != "" ? aws_route53_zone.main[0].name_servers : []
}