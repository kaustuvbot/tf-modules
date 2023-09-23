# Disaster Recovery Patterns

This document describes DR patterns supported by this platform's modules
and the design decisions behind them.

## RTO / RPO Targets

| Tier | RTO | RPO | Pattern |
|---|---|---|---|
| T1 (critical) | < 15 min | < 5 min | Active-active multi-region |
| T2 (important) | < 1 hr | < 15 min | Active-passive with health checks |
| T3 (standard) | < 4 hr | < 1 hr | Backup + restore |

Module hooks in this platform support T2 and T3 patterns out of the box.
T1 active-active requires additional orchestration beyond this module set.

## AWS: Multi-Region Failover

### Route53 + Health Checks

The `modules/aws/vpc` module supports Route53 health checks via:
```hcl
module "vpc" {
  # ...
  enable_route53_health_check    = true
  route53_health_check_fqdn      = "api.myapp.example.com"
  route53_health_check_type      = "HTTPS"
  route53_health_check_port      = 443
}
```

Pair with Route53 failover routing records in your root module:
```hcl
resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.this.id
  name    = "api.myapp.example.com"
  type    = "A"
  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = module.vpc_us_east.route53_health_check_id
  alias { ... }
}

resource "aws_route53_record" "secondary" {
  # same zone, failover type = SECONDARY
  # points to us-west-2 load balancer
}
```

### Multi-Region Provider Pattern

```hcl
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
}

module "vpc_primary" {
  source    = "../../modules/aws/vpc"
  providers = { aws = aws.primary }
  # ...
}

module "vpc_secondary" {
  source    = "../../modules/aws/vpc"
  providers = { aws = aws.secondary }
  # ...
}
```

## Azure: Front Door Failover

The `modules/azure/front-door` module provides a Front Door profile with
multi-origin health probing and automatic failover:

```hcl
module "front_door" {
  source              = "../../modules/azure/front-door"
  project             = var.project
  environment         = var.environment
  resource_group_name = module.rg.name
  sku_name            = "Standard_AzureFrontDoor"

  origins = {
    eastus = {
      host_name  = "app-eastus.example.com"
      priority   = 1
      weight     = 1000
    }
    westus = {
      host_name  = "app-westus.example.com"
      priority   = 2
      weight     = 1000
    }
  }
}
```

Front Door health probes automatically failover traffic when the primary
origin health check fails.

## State Backup

Regardless of the application DR tier, Terraform state is always protected:
- **AWS**: S3 versioning + MFA delete on state bucket
- **Azure**: Blob versioning + soft-delete on state container

To recover a previous state: `terraform state pull` from a specific S3
version, or restore from Azure blob snapshot.

## EKS Cluster Recovery

For T3 recovery:
1. Re-apply Terraform to recreate the cluster
2. Restore workloads from backup (Velero recommended — see `enable_velero_irsa` in EKS module)
3. Restore PVC data from EBS snapshots or EFS backups

Velero IRSA is pre-wired in the EKS module:
```hcl
module "eks" {
  # ...
  enable_velero_irsa = true
}
```
