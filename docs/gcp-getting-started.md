# GCP Getting Started

Guide for using the GCP modules in this repository.

## Prerequisites

### GCP Account Setup

1. Create a GCP project:
   ```bash
   gcloud projects create myproject --name="My Project"
   ```

2. Enable billing:
   ```bash
   gcloud billing projects link myproject --billing-account=XXXXXX-XXXXXX-XXXXXX
   ```

3. Enable required APIs:
   ```bash
   gcloud services enable \
     compute.googleapis.com \
     container.googleapis.com \
     cloudresourcemanager.googleapis.com \
     iam.googleapis.com
   ```

### Terraform Configuration

```hcl
provider "google" {
  project = var.project
  region  = "us-central1"
}

provider "google-beta" {
  project = var.project
  region  = "us-central1"
}
```

## Quick Start

### 1. Create VPC Network

```hcl
module "vpc" {
  source = "./modules/gcp/vpc-network"

  project     = "myproject"
  environment = "prod"

  subnets = {
    "us-central1" = {
      region           = "us-central1"
      ip_cidr_range   = "10.0.1.0/24"
      secondary_ranges = {
        "gke-pods"     = "10.1.0.0/16"
        "gke-services" = "10.2.0.0/16"
      }
    }
  }

  enable_cloud_nat = true
}
```

### 2. Create Service Accounts

```hcl
module "iam" {
  source = "../../modules/gcp/iam"

  project     = "myproject"
  environment = "prod"

  service_accounts = {
    "app" = {
      display_name = "Application Service Account"
    }
  }

  workload_identity_enabled = true
  workload_identity_pool   = "app-pool"
  service_accounts_keys = ["app"]
}
```

### 3. Create GKE Cluster

```hcl
module "gke" {
  source = "../../modules/gcp/gke"

  project     = "myproject"
  environment = "prod"
  location   = "us-central1"

  network_id  = module.vpc.network_id
  subnetwork_id = module.vpc.subnet_ids["us-central1"]

  node_pools = {
    "default" = {
      machine_type = "e2-standard-2"
      node_count  = 3
      disk_type   = "pd-ssd"
    }
    "memory-optimized" = {
      machine_type   = "n2-highmem-4"
      node_count    = 2
      preemptible   = true
    }
  }
}
```

### 4. Deploy Application

```bash
# Get cluster credentials
gcloud container clusters get-credentials gke-myproject-prod --region us-central1

# Deploy
kubectl apply -f deployment.yaml
```

## Module Overview

| Module | Purpose |
|--------|---------|
| `gcp/vpc-network` | VPC, subnets, Cloud NAT, Private Service Access |
| `gcp/iam` | Service accounts, IAM bindings, Workload Identity |
| `gcp/gke` | GKE cluster, node pools, security features |

## Security Features

All modules include security best practices:

- **VPC**: Private Google Access for internal API calls
- **GKE**: Private nodes, Workload Identity, shielded nodes
- **IAM**: Service account per workload, least-privilege roles

## Cost Optimization

1. **Use preemptible instances** for fault-tolerant workloads:
   ```hcl
   node_pools = {
     "batch" = {
       machine_type = "e2-standard-2"
       preemptible = true
     }
   }
   ```

2. **Enable autoscaling**:
   ```hcl
   node_pools = {
     "default" = {
       machine_type  = "e2-standard-2"
       node_count   = 3
       min_node_count = 1
       max_node_count = 5
     }
   }
   ```

3. **Use appropriate machine types** — don't over-provision.

## Next Steps

- Review module READMEs for detailed configuration options
- Add monitoring with Cloud Monitoring
- Set up Cloud CDN for static content
- Configure Cloud Armor for WAF
