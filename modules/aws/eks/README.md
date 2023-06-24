# AWS EKS Module

Manages an EKS cluster with managed node groups, IRSA support, and production-ready defaults.

## Features

- EKS cluster with configurable Kubernetes version
- Multiple managed node groups via `for_each`
- IRSA (IAM Roles for Service Accounts) via OIDC provider
- Control plane logging (all five log types enabled by default)
- Optional KMS encryption for Kubernetes secrets
- Dedicated IAM roles with least-privilege policies

## Usage

```hcl
module "eks" {
  source = "../../modules/aws/eks"

  project         = "myproject"
  environment     = "prod"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 4
    }
    workload = {
      instance_types = ["t3.large"]
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      capacity_type  = "SPOT"
      labels = {
        workload = "general"
      }
    }
  }

  kms_key_arn = module.kms.general_key_arn

  tags = {
    Team = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project` | Project name | `string` | — | yes |
| `environment` | Environment (dev, staging, prod) | `string` | — | yes |
| `cluster_version` | Kubernetes version | `string` | `"1.28"` | no |
| `vpc_id` | VPC ID for the cluster | `string` | — | yes |
| `subnet_ids` | Subnet IDs (min 2, private recommended) | `list(string)` | — | yes |
| `node_groups` | Map of node group configs | `map(object)` | 1 default group | no |
| `kms_key_arn` | KMS key for secrets encryption | `string` | `null` | no |
| `enabled_cluster_log_types` | Control plane log types | `list(string)` | all 5 types | no |
| `tags` | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | EKS cluster ID |
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | Cluster API endpoint |
| `cluster_certificate_authority` | Base64 CA cert for kubeconfig |
| `cluster_security_group_id` | Cluster security group ID |
| `node_group_role_arn` | Node group IAM role ARN |
| `oidc_provider_arn` | OIDC provider ARN (for IRSA) |
| `oidc_provider_url` | OIDC provider URL (without https://) |

## Recommended Production Settings

- Use **private subnets** for node groups
- Enable **KMS encryption** for secrets
- Use **multiple node groups** to separate system and workload pods
- Set `min_size >= 2` for high availability
- Consider **SPOT instances** for non-critical workloads
- Reduce `enabled_cluster_log_types` in dev to save costs

## IRSA Setup

After deploying the cluster, create service account roles:

```hcl
resource "aws_iam_role" "app_role" {
  name = "my-app-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider_url}:sub" = "system:serviceaccount:my-namespace:my-sa"
          "${module.eks.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}
```
