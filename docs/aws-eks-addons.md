# EKS Add-ons Guide

## Overview

The eks-addons module installs Kubernetes controllers that integrate EKS with AWS services. Each add-on uses IRSA (IAM Roles for Service Accounts) — no static credentials are used.

## Architecture

```
EKS Cluster
├── kube-system namespace
│   ├── AWS Load Balancer Controller → creates ALB/NLB
│   └── ExternalDNS → manages Route53 records
└── cert-manager namespace
    └── cert-manager → issues TLS certificates via Route53 DNS01
```

## ALB Controller

Creates Application Load Balancers and Network Load Balancers based on Kubernetes Ingress and Service resources.

**When to enable**: Always. This is the primary ingress mechanism for EKS.

**IAM permissions**: `ElasticLoadBalancingFullAccess` (AWS managed policy). A custom scoped-down policy is recommended for production — will be refined in a future commit.

## ExternalDNS

Automatically creates/updates Route53 DNS records when Kubernetes Services or Ingresses are created.

**When to enable**: When you want automatic DNS management.

**IAM permissions**: Scoped to specific hosted zone IDs via `route53_zone_ids`. Only `ChangeResourceRecordSets` on those zones, plus read-only list operations.

**Ownership**: Uses TXT records with `txtOwnerId` set to `{project}-{environment}` to prevent conflicts when multiple clusters manage the same zones.

## cert-manager

Automates TLS certificate issuance using Let's Encrypt (or other ACME CAs) with Route53 DNS01 challenge validation.

**When to enable**: When you need automated TLS certificates.

**IAM permissions**: Scoped to specific hosted zone IDs. Only needs `ChangeResourceRecordSets` for DNS01 challenge records, plus `GetChange` to poll for propagation.

**Post-install step**: After deploying cert-manager, create a `ClusterIssuer`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: platform@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - dns01:
          route53:
            region: us-east-1
```

## Upgrading Add-ons

1. Check the current version: `helm list -A`
2. Review the chart changelog
3. Update the version variable in your environment tfvars
4. Run `terraform plan` — Helm provider will show a diff
5. Apply to dev first, then staging, then prod

## Known Limitations

1. **ALB controller policy is broad**: Uses the AWS managed `ElasticLoadBalancingFullAccess` policy. A custom least-privilege policy will be created in a future batch.
2. **No Prometheus/Grafana yet**: Observability stack (Prometheus, Grafana, Loki) will be added in Batch 9 (commits 84–86).
3. **No network policies**: CNI-level network policies will be added in commit 83.
