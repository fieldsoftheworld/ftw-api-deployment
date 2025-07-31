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

resource "random_id" "cloudfront_secret" {
  byte_length = 16
}

locals {
  cloudfront_secret = "ftw-cf-secret-${random_id.cloudfront_secret.hex}"
}

provider "aws" {
  region = var.region
}
# This provider is used for resources in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "certificate_manager" {
  source = "../../modules/certificate-manager"

  environment = var.environment
  ssl_config = {
    custom_domain_name = var.custom_domain_name
  }

  # Cert has to be created in us-east-1
  providers = {
    aws.us_east_1 = aws.us_east_1
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

# DynamoDB Module - Project state management
module "dynamodb" {
  source = "../../modules/dynamodb"

  environment                     = var.environment
  vpc_id                          = module.vpc.vpc_id
  private_subnet_ids              = module.vpc.private_subnet_ids
  vpc_endpoint_security_group_ids = [module.security_groups.vpc_endpoints_security_group_id]
  route_table_ids = concat(
    [module.vpc.public_route_table_id],
    module.vpc.private_route_table_ids
  )

  tags = {
    Environment = var.environment
    Project     = "fields-of-the-world"
  }
}

module "iam" {
  source = "../../modules/iam"

  # Required variables
  environment        = var.environment
  region             = var.region
  s3_bucket_arn      = module.s3.output_bucket_arn
  dynamodb_table_arn = module.dynamodb.dynamodb_table_arn
  #sqs_queue_arn                = module.sqs.queue_arn
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  # Required variables
  environment                 = var.environment
  api_name                    = var.api_name
  alb_dns_name                = module.alb.alb_dns_name
  alb_listener_arn            = module.alb.http_listener_arn
  private_subnet_ids          = module.vpc.private_subnet_ids
  vpc_link_security_group_ids = [module.security_groups.api_gateway_vpc_link_security_group_id]

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
  enable_cloudfront_protection    = true
  lambda_authorizer_invoke_arn    = module.lambda_authorizer.authorizer_invoke_arn
  lambda_authorizer_function_name = module.lambda_authorizer.authorizer_function_name
  depends_on = [module.certificate_manager]
}

# Route53 record for custom domain
resource "aws_route53_record" "api_custom_domain" {
  count   = var.custom_domain_name != "" ? 1 : 0
  zone_id = module.certificate_manager.route53_zone_id
  name    = var.custom_domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.cloudfront_domain_name
    zone_id                = module.cloudfront.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.certificate_manager, module.cloudfront]
}

module "security_groups" {
  source = "../../modules/security-groups"

  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  vpc_cidr_block          = module.vpc.vpc_cidr_block
  enable_vpc_endpoints_sg = true
}

module "alb" {
  source = "../../modules/alb"

  # ALB uses simple http as https stops at gateway
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  alb_security_group_ids = [module.security_groups.alb_security_group_id]

  alb_config = {
    health_check_interval = 300
  }

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
# WAF Module - Web Application Firewall for CloudFront
module "waf" {
  source = "../../modules/waf"

  environment = var.environment
  rate_limit  = 2000 # 2000 requests per 5 minutes per IP

  tags = {
    Environment = var.environment
    Project     = "fields-of-the-world"
  }
  providers = {
    aws = aws.us_east_1
  }
}

# CloudFront Module - CDN with WAF protection
module "cloudfront" {
  source = "../../modules/cloudfront"

  environment            = var.environment
  api_gateway_invoke_url = module.api_gateway.api_endpoint
  waf_web_acl_arn        = module.waf.web_acl_arn
  custom_domain_name     = var.custom_domain_name
  certificate_arn        = module.certificate_manager.cloudfront_certificate_arn
  cloudfront_secret_header = local.cloudfront_secret  

  tags = {
    Environment = var.environment
    Project     = "fields-of-the-world"
  }
  depends_on = [module.waf, module.api_gateway, module.certificate_manager]
}
# Lambda Authorizer for CloudFront secret validation
module "lambda_authorizer" {
  source = "../../modules/lambda-authorizer"
  
  environment       = var.environment
  cloudfront_secret = local.cloudfront_secret
  
  tags = {
    Environment = var.environment
    Project     = "fields-of-the-world"
  }
}


