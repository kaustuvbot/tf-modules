# AWS VPC Module

Creates a production-ready VPC with public and private subnets, internet gateway, and optional NAT gateway across multiple availability zones.

## Usage

```hcl
module "vpc" {
  source = "../../modules/aws/vpc"

  project     = "myapp"
  environment = "dev"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true  # Use one NAT for cost savings

  tags = {
    Team = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_cidr` | CIDR block for the VPC (/16 to /24) | `string` | `"10.0.0.0/16"` | no |
| `project` | Project name (2-32 chars) | `string` | — | yes |
| `environment` | Environment: dev, staging, prod | `string` | — | yes |
| `availability_zones` | List of AZs (1-3) | `list(string)` | — | yes |
| `public_subnet_cidrs` | CIDR blocks for public subnets | `list(string)` | `[]` | no |
| `private_subnet_cidrs` | CIDR blocks for private subnets | `list(string)` | `[]` | no |
| `enable_nat_gateway` | Create NAT gateway(s) | `bool` | `false` | no |
| `single_nat_gateway` | Single NAT vs per-AZ | `bool` | `true` | no |
| `tags` | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the VPC |
| `vpc_cidr` | The CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `internet_gateway_id` | The ID of the Internet Gateway |
| `nat_gateway_ids` | List of NAT gateway IDs |
| `public_route_table_id` | The ID of the public route table |
| `private_route_table_ids` | List of private route table IDs |

## Design Decisions

- **Count-based subnets**: Uses `count` over `for_each` for simplicity since subnet CIDRs are ordered by AZ index.
- **Conditional IGW**: Internet gateway is only created if public subnets exist.
- **Single vs multi NAT**: Single NAT saves ~$32/month per extra gateway. Use per-AZ NAT in production for HA.
- **DNS enabled by default**: Both `enable_dns_support` and `enable_dns_hostnames` are true for EKS/service discovery compatibility.
