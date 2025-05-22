terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "ftw-api-terraform-state" # should match bucket created in bootstrap-s3.sh
    key          = "dev/terraform.tfstate"
    region       = "us-east-1" # hardcoded - cannot use variables here
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