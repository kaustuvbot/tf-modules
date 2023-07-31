# Observability Stack

## Overview

The EKS add-ons module ships optional Helm-based observability components:

| Component | Chart | Default namespace | Flag |
|-----------|-------|-------------------|------|
| Prometheus + Grafana + Alertmanager | `kube-prometheus-stack` | `monitoring` | `enable_prometheus` |
| Loki + Promtail | `loki-stack` | `monitoring` | `enable_loki` |

## Usage

```hcl
module "eks_addons" {
  source = "../../modules/aws/eks-addons"
  # ... required vars ...

  enable_prometheus      = true
  prometheus_version     = "55.5.0"
  grafana_admin_password = var.grafana_password  # use secrets manager in prod

  enable_loki    = true
  loki_version   = "2.10.2"
}
```

## Install Ordering

Loki depends on Prometheus (`depends_on = [helm_release.prometheus]`) because it disables its bundled Grafana and expects the Prometheus-stack Grafana to be available. If you enable Loki without Prometheus, remove that `depends_on` or install a standalone Grafana.

## Accessing Grafana

Port-forward to the Grafana service:

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Default credentials: `admin` / value of `grafana_admin_password`.

## Loki Data Source

Add Loki as a Grafana data source pointing to `http://loki-stack:3100`. With Promtail installed, pod logs are automatically shipped.

## Production Considerations

- **Storage**: Both Prometheus and Loki default to 20 Gi and 10 Gi PVCs respectively. Size these based on your log/metric volume and retention requirements.
- **Retention**: Prometheus defaults to 15 days. Adjust `prometheus.prometheusSpec.retention` via `set` overrides or `values` files.
- **Grafana password**: Pass the password via a secrets manager reference, not a plaintext variable. Use `sensitive = true` and source from AWS Secrets Manager or Vault.
- **HA**: For production, switch to a HA Prometheus and Loki deployment (e.g., Thanos, Loki distributed mode).
