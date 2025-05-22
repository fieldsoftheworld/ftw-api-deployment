# ftw-api-deployment

Terraform infrastructure as code for FTW API deployment on AWS. 
## Prerequisites

- AWS CLI v2 installed and configured
- Terraform >= 1.10 installed
- AWS account with appropriate permissions

## Infrastructure Overview

This Terraform configuration creates:

- VPC with DNS support and hostnames enabled
- Public subnets in 2 availability zones
- Private subnets in 2 availability zones  
- Internet Gateway for public subnet access
- NAT Gateway(s) for private subnet outbound access
- Route tables and associations
- Configurable single or dual NAT gateway setup

### Network CIDR Layout

With the default VPC CIDR block of `10.0.0.0/16`:

| Subnet | CIDR Block | Availability Zone | Type |
|--------|------------|-------------------|------|
| Public AZ1 | `10.0.0.0/24` | us-east-1a | Public |
| Public AZ2 | `10.0.1.0/24` | us-east-1b | Public |
| Private AZ1 | `10.0.2.0/24` | us-east-1a | Private |
| Private AZ2 | `10.0.3.0/24` | us-east-1b | Private |

Each subnet provides 256 IP addresses (251 usable after AWS reserved IPs).

## Project Structure

```
.
├── environments/
│   └── dev/
│       ├── main.tf           # Main configuration
│       ├── variables.tf      # Variable definitions
│       └── terraform.tfvars  # Environment-specific values
├── modules/
│   └── vpc/
│       ├── main.tf           # VPC module resources
│       ├── variables.tf      # Module variables
│       └── outputs.tf        # Module outputs
└── scripts/
    └── bootstrap-s3.sh       # S3 backend setup script
```

## Getting Started

### One-Time Setup (First User Only)

1. Clone this repository
2. Configure AWS credentials: `aws configure`
3. Update the bucket name in `scripts/bootstrap-s3.sh` if needed
4. Create the S3 backend: `./scripts/bootstrap-s3.sh`

### Deploy Infrastructure

1. Navigate to your desired environment: `cd environments/dev`
2. Copy the example variables: `cp terraform.tfvars.example terraform.tfvars`
3. Edit terraform.tfvars with your specific values
4. Initialize Terraform: `terraform init`
5. Review the plan: `terraform plan`
6. Apply the configuration: `terraform apply`

## Configuration

### Environment Variables

Key variables you can customize in `terraform.tfvars`:

- `region` - AWS region for deployment
- `vpc_cidr_block` - CIDR block for the VPC
- `environment` - Environment name (dev, staging, prod)
- `single_nat_gateway` - Use one NAT gateway (cost-effective) vs one per AZ (high availability)

### Example terraform.tfvars

```hcl
region             = "us-east-1"
vpc_cidr_block     = "10.0.0.0/16"
environment        = "dev"
single_nat_gateway = true
```

## Cost Optimization

- **Development**: Set `single_nat_gateway = true` to use one NAT gateway
- **Production**: Set `single_nat_gateway = false` for high availability with NAT gateways in each AZ

## Outputs

After successful deployment, the following outputs are available:

- `vpc_id` - The ID of the created VPC
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs
- `nat_gateway_ips` - Public IP addresses of NAT gateway(s)

## Clean Up

To destroy the infrastructure:

```bash
cd environments/dev
terraform destroy
```