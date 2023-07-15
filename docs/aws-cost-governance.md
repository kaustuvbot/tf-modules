# AWS Cost Governance

## Overview

This platform includes cost controls at three layers:

1. **Budgets** — hard dollar thresholds with email alerts
2. **Anomaly Detection** — ML-based detection of unexpected spend spikes
3. **Tag Enforcement** — required tags enable cost allocation and attribution

---

## Budgets Module

```hcl
module "budgets" {
  source = "../../modules/aws/budgets"

  project     = "myproject"
  environment = "prod"

  monthly_budget_amount = 500
  currency              = "USD"
  alert_email_addresses = ["platform@example.com"]

  # Optional: filter costs by tag
  cost_filters = {
    "TagKeyValue" = "user:Environment$prod"
  }

  # Anomaly detection
  enable_anomaly_detection = true
  anomaly_threshold_amount = 50
}
```

### Budget Alerts

| Alert | Threshold | Type | When it fires |
|-------|-----------|------|---------------|
| Monthly 80% | 80% of limit | ACTUAL | $400 spent of $500 |
| Monthly 100% | 100% of limit | ACTUAL | $500 spent |
| Monthly forecast 110% | 110% of limit | FORECASTED | On track to spend $550 |
| Forecast early warning | 90% of limit | FORECASTED | Projected to hit $450 |

### Cost Anomaly Detection

Anomaly detection uses AWS Cost Explorer ML models to identify spend patterns that deviate from baseline. Unlike budget alerts, it catches:

- Sudden unexpected service charges
- Resource misconfiguration causing runaway spend
- Forgotten resources left running

Default threshold: **$20 absolute impact**. Lower for dev/test environments, raise for production to reduce noise.

---

## Tag Enforcement

Required tags on all resources:

| Tag | Purpose | Example |
|-----|---------|---------|
| `Project` | Cost allocation by project | `myproject` |
| `Environment` | Cost allocation by environment | `prod` |
| `ManagedBy` | Identify Terraform-managed resources | `terraform` |

Tags are validated in CI using Conftest + OPA policy at `policy/required_tags.rego`. Currently **soft-fail** — violations appear as warnings. Will switch to hard-fail in Phase 4.

---

## Keeping Costs Low in Demo/Dev Environments

| Resource | Cost-saving setting |
|----------|-------------------|
| EKS node groups | Use `capacity_type = "SPOT"` for non-system pools |
| NAT Gateway | Use `single_nat_gateway = true` |
| CloudTrail | Disable in dev (`enable_cloudtrail = false`) |
| AWS Config | Disable in dev (`enable_config = false`) |
| KMS keys | Reduce `deletion_window_in_days` to 7 for dev |
| CloudWatch logs | Set `retention_in_days = 7` for dev |
| EKS control plane logs | Disable audit logs in dev |
| Anomaly detection | Set `anomaly_threshold_amount = 5` in dev |

### Dev Environment Example

```hcl
module "budgets" {
  monthly_budget_amount    = 50
  anomaly_threshold_amount = 5
}

module "logging" {
  enable_cloudtrail = false
  enable_config     = false
  retention_in_days = 7
}

module "eks" {
  enabled_cluster_log_types = ["api", "authenticator"]
  node_groups = {
    default = {
      capacity_type = "SPOT"
      desired_size  = 1
      min_size      = 1
      max_size      = 3
    }
  }
}
```

---

## Cost Attribution Flow

```
AWS Spend
  └── Cost Explorer
        ├── Tag: Project=myproject  → per-project dashboard
        ├── Tag: Environment=prod   → per-env breakdown
        └── Anomaly Monitor         → unexpected spike alerts
```

Use AWS Cost Explorer grouped by `Project` tag to see spend breakdown per project.
