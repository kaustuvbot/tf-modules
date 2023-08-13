# EKS Add-ons Guide

## Two Types of Add-ons

This library manages EKS add-ons in two separate modules:

| Module | Add-on type | Examples |
|--------|-------------|---------|
| `modules/aws/eks` (managed-addons.tf) | AWS EKS Managed Add-ons | vpc-cni, coredns, kube-proxy |
| `modules/aws/eks-addons` | Helm-based add-ons | ALB controller, ExternalDNS, cert-manager, Prometheus, Loki |

---

## EKS Managed Add-ons

AWS manages patching and upgrades for these core components. Prefer managed add-ons over self-managed equivalents where available.

```hcl
module "eks" {
  # ...
  enable_managed_addons = true   # default

  # Pin versions (recommended for prod)
  vpc_cni_version    = "v1.15.1-eksbuild.1"
  coredns_version    = "v1.10.1-eksbuild.4"
  kube_proxy_version = "v1.28.1-eksbuild.1"
}
```

Leave version as `null` to always use the latest version recommended for your cluster version (suitable for dev).

### Finding Available Versions

```bash
aws eks describe-addon-versions \
  --kubernetes-version 1.28 \
  --addon-name vpc-cni \
  --query 'addons[].addonVersions[].addonVersion'
```

### Conflict Resolution

- `resolve_conflicts_on_create = "OVERWRITE"`: Overwrite any existing self-managed component on first install.
- `resolve_conflicts_on_update = "PRESERVE"`: Preserve custom configuration when updating the add-on version.

---

## Helm-based Add-ons

Managed by the `eks-addons` module using the Helm provider. These are not available as EKS managed add-ons and require IRSA for AWS API access.

```hcl
module "eks_addons" {
  source = "../../modules/aws/eks-addons"
  # ...

  enable_alb_controller = true
  enable_external_dns   = true
  enable_cert_manager   = true
  enable_prometheus     = true
  enable_loki           = true
}
```

### Install Order

```
ALB Controller
ExternalDNS
cert-manager (depends_on: ALB controller)
kube-prometheus-stack
loki-stack (depends_on: kube-prometheus-stack)
```

All Helm releases use `atomic = true` for automatic rollback on failure.

---

## Decision Matrix

| Need | Use |
|------|-----|
| Core networking (CNI, DNS) | EKS Managed Add-ons |
| Load balancer integration | Helm (ALB controller) |
| TLS certificates | Helm (cert-manager) |
| DNS automation | Helm (ExternalDNS) |
| Metrics and alerting | Helm (kube-prometheus-stack) |
| Log aggregation | Helm (loki-stack) |
