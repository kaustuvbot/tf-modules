# Observability Guide

This guide covers the full observability stack available for EKS clusters
via the `modules/aws/eks-addons` module.

## Stack Overview

| Component | Helm Chart | Purpose |
|---|---|---|
| Prometheus | kube-prometheus-stack | Metrics collection, alerting rules |
| Alertmanager | (part of kube-prometheus) | Alert routing and deduplication |
| Grafana | grafana | Dashboards and visualization |
| Loki | loki | Log aggregation |
| Node Exporter | (part of kube-prometheus) | Node-level metrics |

All components are installed in the `monitoring` namespace.

## Enabling the Stack

```hcl
module "eks_addons" {
  source = "../../modules/aws/eks-addons"
  # ... required variables ...

  # Observability stack
  enable_prometheus = true
  prometheus_retention     = "30d"
  prometheus_storage_size  = "100Gi"
  enable_alertmanager      = true

  enable_grafana               = true
  grafana_persistence_enabled  = true
  grafana_storage_size         = "10Gi"

  enable_loki         = true
  loki_s3_bucket_name = "my-loki-chunks"
  loki_irsa_role_arn  = aws_iam_role.loki.arn
}
```

## Install Ordering

The following dependency graph is enforced via Helm atomic installs and `depends_on`:

```
cert-manager
    └── alb-controller
            └── external-dns

prometheus  ──► grafana (data source pre-configured)

loki        (independent)
```

## Prometheus Configuration

### Storage

Prometheus stores metrics locally on a PVC. Size with:
- 15-day retention, 1 cluster: ~20–30 GiB
- 30-day retention, 1 cluster: ~50–80 GiB (depends on workload count)

Use `prometheus_retention` and `prometheus_storage_size` to tune.

### Alert Rules

Default alerting rules come from the `kube-prometheus-stack` chart (based on
the Kubernetes Monitoring Mixin). Custom rules can be added via `PrometheusRule`
CRDs after the stack is installed.

## Grafana Dashboards

Grafana is pre-configured with Prometheus as the default data source.

Default dashboards included by kube-prometheus-stack:
- Kubernetes cluster overview
- Node resource usage
- Pod resource usage
- Namespace resource usage

### Accessing Grafana

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# Open http://localhost:3000
# Default credentials: admin / prom-operator
```

## Loki Log Aggregation

Loki stores logs in S3 for durability and cost efficiency.

### S3 Bucket Requirements

The Loki S3 bucket must:
- Exist before `terraform apply` (or be created in the same root module)
- Allow the Loki IRSA role to `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:ListBucket`
- Have versioning and server-side encryption enabled

### Querying Logs

Loki is accessible via Grafana's Explore view. Use LogQL:

```logql
{namespace="production", app="myapp"} |= "error"
```

## Cost Considerations

- Prometheus PVC: $0.10/GiB-month (gp3) → ~$5–10/month for standard retention
- Grafana PVC: minimal (~$1/month)
- Loki S3: standard S3 pricing — typically $1–5/month for moderate log volumes
- All components run on existing node groups — no dedicated nodes required

## Upgrading

Chart versions are pinned in variables. To upgrade:
1. Test new chart version in dev environment
2. Update `prometheus_version`, `grafana_version`, `loki_version` in your tfvars
3. Run `terraform plan` and review the Helm diff
4. Apply in staging, then production
