# GCP Readiness

This document describes the planned GCP modules for this platform, their intended
interfaces, and the conventions that will govern GCP resource management.

## Status

GCP support is **planned**. The `modules/gcp/` folder scaffolding is in place.
Full module implementation begins in the next development phase.

## Planned Modules

| Module | Path | Purpose |
|---|---|---|
| VPC | `modules/gcp/vpc` | Shared VPC, subnets, secondary ranges, firewall rules |
| GKE | `modules/gcp/gke` | GKE cluster, node pools, Workload Identity |
| IAM | `modules/gcp/iam` | Service accounts, project IAM bindings, WI bindings |
| Logging | `modules/gcp/logging` | Log sinks (GCS/BigQuery), alert policies |
| Budgets | `modules/gcp/budgets` | Billing account budgets, Pub/Sub notifications |

## Naming Conventions

| Concept | AWS | Azure | GCP |
|---|---|---|---|
| Tags | `tags = map(string)` | `tags = map(string)` | `labels = map(string)` |
| Region | `region` | `location` | `region` |
| Project scope | Account/VPC | Subscription/RG | `project_id` |

All GCP modules will expose:
- `project_id` — GCP project to deploy into
- `region` — GCP region (e.g., `us-central1`)
- `labels` — map of GCP labels (equivalent to tags)

## Provider Requirements

All GCP modules require:
```hcl
provider "google" {
  project = var.project_id
  region  = var.region
}
```

Authentication via Workload Identity Federation is the recommended approach
for CI/CD pipelines. Service account key files must not be committed.

## Interfaces (Planned)

### `modules/gcp/vpc`
```hcl
module "vpc" {
  source     = "../../modules/gcp/vpc"
  project_id = var.project_id
  region     = var.region
  network_name = "${var.project}-${var.environment}"
  subnets = [
    {
      name          = "nodes"
      cidr          = "10.10.0.0/20"
      secondary_ranges = {
        pods     = "10.20.0.0/16"
        services = "10.30.0.0/20"
      }
    }
  ]
  labels = local.labels
}
```

### `modules/gcp/gke`
```hcl
module "gke" {
  source          = "../../modules/gcp/gke"
  project_id      = var.project_id
  region          = var.region
  cluster_name    = "${var.project}-${var.environment}"
  network         = module.vpc.network_name
  subnetwork      = module.vpc.subnet_name
  pods_range      = "pods"
  services_range  = "services"
  enable_workload_identity = true
  enable_private_cluster   = true
  labels          = local.labels
}
```

## Migration Path from AWS/Azure

The GCP modules will follow the same variable conventions as AWS and Azure modules
where practical, reducing cognitive load when managing multi-cloud deployments.
Breaking differences will be documented in migration notes per module.
