terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "ftw-api-terraform-state" # should match bucket created in bootstrap-s3.sh
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
  environment = var.environment
  region      = var.region
  s3_bucket_arn = module.s3.output_bucket_arn
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