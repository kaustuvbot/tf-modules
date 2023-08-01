# AWS EKS Add-ons Module

Manages Kubernetes add-ons for EKS clusters via Helm with IRSA-based authentication.

## Add-ons Included

| Add-on | Purpose | Default |
|--------|---------|---------|
| AWS Load Balancer Controller | ALB/NLB ingress management | Enabled |
| ExternalDNS | Automatic Route53 DNS records | Disabled |
| cert-manager | TLS certificate automation | Disabled |
| kube-prometheus-stack | Prometheus + Grafana + Alertmanager | Disabled |
| loki-stack | Loki log aggregation + Promtail | Disabled |

## Usage

```hcl
module "eks_addons" {
  source = "../../modules/aws/eks-addons"

  project     = "myproject"
  environment = "prod"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  region                 = var.region
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  vpc_id                 = module.vpc.vpc_id

  # ALB Controller (enabled by default)
  enable_alb_controller  = true
  alb_controller_version = "1.6.2"

  # ExternalDNS
  enable_external_dns  = true
  external_dns_version = "1.14.3"
  route53_zone_ids     = ["Z1234567890"]

  # cert-manager
  enable_cert_manager  = true
  cert_manager_version = "1.13.3"

  tags = {
    Team = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project` | Project name | `string` | — |
| `environment` | Environment name | `string` | — |
| `cluster_name` | EKS cluster name | `string` | — |
| `cluster_endpoint` | API server endpoint | `string` | — |
| `cluster_ca_certificate` | Base64 CA certificate | `string` | — |
| `region` | AWS region | `string` | — |
| `oidc_provider_arn` | OIDC provider ARN | `string` | — |
| `oidc_provider_url` | OIDC provider URL | `string` | — |
| `vpc_id` | VPC ID | `string` | — |
| `enable_alb_controller` | Install ALB controller | `bool` | `true` |
| `alb_controller_version` | ALB controller chart version | `string` | `"1.6.2"` |
| `enable_external_dns` | Install ExternalDNS | `bool` | `false` |
| `external_dns_version` | ExternalDNS chart version | `string` | `"1.14.3"` |
| `route53_zone_ids` | Route53 zone IDs for DNS | `list(string)` | `[]` |
| `enable_cert_manager` | Install cert-manager | `bool` | `false` |
| `cert_manager_version` | cert-manager chart version | `string` | `"1.13.3"` |
| `tags` | Additional tags | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `alb_controller_role_arn` | ALB controller IRSA role ARN |
| `external_dns_role_arn` | ExternalDNS IRSA role ARN |
| `cert_manager_role_arn` | cert-manager IRSA role ARN |
| `prometheus_namespace` | Namespace of the Prometheus stack (null if disabled) |
| `loki_namespace` | Namespace of Loki (null if disabled) |

## Version Pinning

All chart versions are pinned via variables. Before upgrading:

1. Check the chart changelog for breaking changes
2. Test in dev first
3. Update the version variable
4. Run `terraform plan` to review changes

## Install Order

The module enforces this installation order:

1. ALB Controller (no dependencies)
2. ExternalDNS (no dependencies)
3. cert-manager (depends on ALB controller)
4. kube-prometheus-stack (no dependencies)
5. loki-stack (depends on kube-prometheus-stack)

All releases use `atomic = true` for clean rollback on failure.
