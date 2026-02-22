# Multi-Cloud Architecture Guide

Comparing AWS, Azure, and GCP patterns for consistent multi-cloud deployments.

## Compute Comparison

| Aspect | AWS EKS | Azure AKS | GCP GKE |
|--------|---------|-----------|---------|
| Control Plane | Managed | Managed | Managed |
| Node Pools | Managed Node Groups | Node Pools | Node Pools |
| Serverless | EKS Fargate | AKS Virtual Nodes | GKE Autopilot |
| Version Lag | 1-2 versions | 1-2 versions | Latest |

## Networking Comparison

| Aspect | AWS | Azure | GCP |
|--------|-----|-------|-----|
| Virtual Network | VPC | VNet | VPC |
| Subnets | Per AZ | Per region | Per region |
| Private DNS | Route53 Private Zones | Private DNS Zones | Cloud DNS |
| Load Balancers | ALB/NLB | Application Gateway | Cloud Load Balancing |
| CDN | CloudFront | Azure Front Door | Cloud CDN |
| NAT | NAT Gateway | NAT Gateway | Cloud NAT |

## Security Comparison

| Aspect | AWS | Azure | GCP |
|--------|-----|-------|-----|
| Key Management | KMS | Key Vault | Cloud KMS |
| Secrets | Secrets Manager | Key Vault | Secret Manager |
| Identity | IAM | Azure AD | Cloud IAM |
| Firewall | Security Groups + WAF | NSG + WAF | Firewall Rules + Cloud Armor |
| Container Security | ECR + Inspector | ACR + Defender | Container Registry + Artifact Analysis |

## Storage Comparison

| Aspect | AWS | Azure | GCP |
|--------|-----|-------|-----|
| Object Storage | S3 | Blob Storage | Cloud Storage |
| Block Storage | EBS | Managed Disks | Persistent Disk |
| File Storage | EFS | Azure Files | Filestore |
| Archive | S3 Glacier | Archive Storage | Cloud Storage Archive |

## Module Equivalency

| Category | AWS | Azure | GCP |
|----------|-----|-------|-----|
| Networking | aws/vpc | azure/vnet | gcp/vpc-network |
| Kubernetes | aws/eks | azure/aks | gcp/gke |
| Key Management | aws/kms | azure/key-vault | gcp/cloudkms |
| Storage | aws/s3-state | azure/storage | gcp/storage |
| IAM | aws/iam | azure/iam | gcp/iam |
| Container Registry | aws/ecr | azure/container-registry | gcp/container-registry |

## Unified Patterns

### Tagging/Labels

```hcl
# AWS (Title_Case)
{ Project = "myapp", Environment = "prod", ManagedBy = "terraform" }

# Azure (Title_Case)
{ Project = "myapp", Environment = "prod", ManagedBy = "terraform" }

# GCP (lowercase)
{ project = "myapp", environment = "prod", managed_by = "terraform" }
```

### Resource Naming

```hcl
# AWS
"myapp-prod-vpc"

# Azure
"myapp-prod-vnet"

# GCP (lowercase)
"myapp-prod-vpc"
```

### Network CIDRs

Avoid overlap when deploying multi-cloud:

| Cloud | Production CIDR |
|-------|----------------|
| AWS | 10.0.0.0/16 |
| Azure | 10.1.0.0/16 |
| GCP | 10.2.0.0/16 |

## Disaster Recovery

### Multi-Cloud HA Architecture

```
                    ┌─────────────────────────┐
                    │   Global DNS (Route53)  │
                    └───────────┬─────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  AWS Region   │     │ Azure Region  │     │  GCP Region   │
│  (primary)   │     │  (secondary)  │     │  (tertiary)   │
│               │     │               │     │               │
│ EKS + ALB    │     │ AKS + App GW  │     │ GKE + CLB    │
│ S3 + CloudFr  │     │ Blob + FrontD │     │ GCS + CDN    │
└───────────────┘     └───────────────┘     └───────────────┘
```

### Failover Strategy

1. **Active-Passive**: Primary cloud serves traffic, secondary stands by
2. **Active-Active**: All clouds serve traffic, DNS weighted routing
3. **Pilot Light**: Minimal resources in secondary, scale on failover

## Platform Blueprint

Use `multi/platform-blueprint` for consistent deployments:

```hcl
# AWS deployment
module "platform" {
  source = "../../modules/multi/platform-blueprint"

  cloud = "aws"
  project = "myapp"
  environment = "prod"

  aws_config = {
    region             = "us-east-1"
    vpc_cidr           = "10.0.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b"]
  }
}
```

## Cost Comparison

| Service | AWS | Azure | GCP |
|---------|-----|-------|-----|
| Compute (per vCPU/hr) | ~$0.04 | ~$0.04 | ~$0.04 |
| Storage (per GB/mo) | ~$0.02 | ~$0.02 | ~$0.02 |
| Egress (per GB) | ~$0.09 | ~$0.09 | ~$0.12 |
| Load Balancer | ~$0.02/hr | ~$0.02/hr | ~$0.02/hr |

Prices vary by region and usage patterns.

## Choosing a Cloud

- **AWS**: Enterprise, mature ecosystem, widest service coverage
- **Azure**: Microsoft integration, hybrid cloud, enterprise AD
- **GCP**: Data/ML, Kubernetes native, competitive pricing
