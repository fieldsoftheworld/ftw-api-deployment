terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "ftw-api-terraform-state-cdf18f31" # should match bucket created in bootstrap-s3.sh
    key          = "dev/terraform.tfstate"
    region       = "us-west-2" # hardcoded - cannot use variables here
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "certificate_manager" {
  source = "../../modules/certificate-manager"

  environment = var.environment
  ssl_config = {
    custom_domain_name = var.custom_domain_name
  }
}

module "vpc" {
  source = "../../modules/vpc"

  # Required variables
  region         = var.region
  vpc_cidr_block = var.vpc_cidr_block
  environment    = var.environment

  # Optional variables
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  single_nat_gateway   = var.single_nat_gateway
}

module "s3" {
  source = "../../modules/s3"

  # Required variables
  vpc_id      = module.vpc.vpc_id
  region      = var.region
  environment = var.environment

  # Optional variables
  ftw_api_model_outputs_bucket = var.ftw_api_model_outputs_bucket

  # Route table IDs for s3 gateway endpoint
  route_table_ids = concat(
    [module.vpc.public_route_table_id],
    module.vpc.private_route_table_ids
  )
}

module "iam" {
  source = "../../modules/iam"

  # Required variables
  environment   = var.environment
  region        = var.region
  s3_bucket_arn = module.s3.output_bucket_arn
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  # Required variables
  environment = var.environment
  api_name    = var.api_name

  # API configuration
  api_config = {
    auto_deploy              = var.api_auto_deploy
    log_retention_days       = var.api_log_retention_days
    cors_allow_origins       = var.api_cors_allow_origins
    detailed_metrics_enabled = var.api_detailed_metrics_enabled
    throttling_burst_limit   = var.api_throttling_burst_limit
    throttling_rate_limit    = var.api_throttling_rate_limit
    custom_domain_name       = var.custom_domain_name
    certificate_arn          = module.certificate_manager.certificate_arn
  }

  depends_on = [module.certificate_manager]
}

# Route53 record for custom domain
resource "aws_route53_record" "api_custom_domain" {
  count   = var.custom_domain_name != "" ? 1 : 0
  zone_id = module.certificate_manager.route53_zone_id
  name    = var.custom_domain_name
  type    = "A"

  alias {
    name                   = module.api_gateway.domain_name
    zone_id                = module.api_gateway.domain_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.certificate_manager, module.api_gateway]
}

module "security_groups" {
  source = "../../modules/security-groups"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

module "alb" {
  source = "../../modules/alb"

  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  alb_security_group_ids = [module.security_groups.alb_security_group_id]
  certificate_arn        = module.certificate_manager.certificate_arn

  depends_on = [module.certificate_manager]
}

module "ec2" {
  source = "../../modules/ec2"

  # Required variables
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.security_groups.ec2_fastapi_security_group_id]
  instance_profile_name = module.iam.ec2_fastapi_instance_profile_name
  target_group_arn      = module.alb.target_group_arn

  # Optional variables
  instance_type = var.instance_type
  key_pair_name = var.key_pair_name
  asg_config    = var.asg_config
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "Public IP addresses of the NAT Gateway(s)"
  value       = module.vpc.nat_gateway_ips
}

output "s3_bucket_id" {
  description = "The name of the model output s3 bucket"
  value       = module.s3.output_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the model output s3 bucket"
  value       = module.s3.output_bucket_arn
}

output "s3_vpc_endpoint_id" {
  description = "The ID of the S3 VPC endpoint"
  value       = module.s3.vpc_endpoint_id
}

output "api_gateway_id" {
  description = "The ID of the API Gateway HTTP API"
  value       = module.api_gateway.api_id
}

output "api_gateway_endpoint" {
  description = "The endpoint URL of the API Gateway"
  value       = module.api_gateway.api_endpoint
}

output "api_gateway_stage_invoke_url" {
  description = "The invoke URL for the API Gateway stage"
  value       = module.api_gateway.stage_invoke_url
}

output "api_url" {
  description = "The primary API URL (custom domain if configured, otherwise AWS generated)"
  value       = var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : module.api_gateway.stage_invoke_url
}

output "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate (empty if using AWS generated URL)"
  value       = module.certificate_manager.certificate_arn
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = module.ec2.autoscaling_group_name
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = module.ec2.launch_template_id
}

output "ami_id" {
  description = "The AMI ID used by the EC2 instances"
  value       = module.ec2.ami_id
}