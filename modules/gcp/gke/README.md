# GCP GKE Module

Manages a Google Kubernetes Engine cluster with node pools, workload identity,
shielded nodes, and security hardening features.

## Usage

### Basic GKE Cluster

```hcl
module "gke" {
  source = "../../modules/gcp/gke"

  project        = "my-project"
  environment   = "prod"
  location      = "us-central1"
  network_id    = module.vpc.network_id
  subnetwork_id = module.vpc.subnetwork_id

  node_pools = {
    default = {
      machine_type = "e2-standard-2"
      node_count   = 3
    }
  }

  labels = {
    team = "platform"
  }
}
```

### GKE with Workload Identity and Node Pool Autoscaling

```hcl
module "gke_production" {
  source = "../../modules/gcp/gke"

  project        = "my-project"
  environment   = "prod"
  location      = "us-central1"
  network_id    = module.vpc.network_id
  subnetwork_id = module.vpc.subnetwork_id

  enable_private_nodes    = true
  enable_private_endpoint = true

  workload_identity_enabled = true

  enable_shielded_nodes = true
  enable_network_policy  = true

  node_pools = {
    system = {
      machine_type    = "e2-standard-4"
      node_count      = 3
      min_node_count  = 3
      max_node_count  = 10
      disk_type       = "pd-ssd"
      disk_size_gb    = 100
      preemptible     = false
    }
    workloads = {
      machine_type    = "e2-standard-2"
      node_count      = 2
      min_node_count  = 0
      max_node_count  = 20
      preemptible     = true
    }
  }
}
```

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `project` | `string` | GCP project ID |
| `environment` | `string` | Environment: `dev`, `staging`, or `prod` |
| `network_id` | `string` | VPC network ID |
| `subnetwork_id` | `string` | Subnet ID |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `string` | `us-central1` | GCP region or zone |
| `initial_node_count` | `number` | `1` | Initial nodes in default pool |
| `enable_shielded_nodes` | `bool` | `true` | Enable Shielded Nodes |
| `enable_private_nodes` | `bool` | `true` | Private nodes (no public IP) |
| `enable_private_endpoint` | `bool` | `true` | Private control plane endpoint |
| `master_ipv4_cidr_block` | `string` | `172.16.0.0/28` | Master CIDR block |
| `master_authorized_networks_enabled` | `bool` | `false` | Enable authorized networks |
| `enable_network_policy` | `bool` | `true` | Enable network policy |
| `enable_binary_authorization` | `bool` | `false` | Enable Binary Authorization |
| `enable_database_encryption` | `bool` | `false` | Enable CMEK for etcd |
| `database_encryption_key` | `string` | `""` | KMS key URI for etcd |
| `workload_identity_enabled` | `bool` | `true` | Enable Workload Identity |
| `node_pools` | `map(object)` | `{}` | Node pool configurations |
| `labels` | `map(string)` | `{}` | Additional labels |

### node_pools object shape

```hcl
node_pools = {
  "pool-name" = {
    machine_type               = "e2-standard-2"  # required
    node_count                 = 3                # required
    min_node_count             = 1                # optional, default 1
    max_node_count             = 3                # optional, default 3
    disk_type                  = "pd-ssd"         # optional, default pd-ssd
    disk_size_gb               = 100              # optional, default 100
    service_account            = null              # optional
    preemptible                = false             # optional, default false
    labels                     = {}                # optional
    enable_secure_boot         = true              # optional, default true
    enable_integrity_monitoring = true              # optional, default true
    auto_repair               = true              # optional, default true
    auto_upgrade              = true              # optional, default true
    max_surge                 = null              # optional
    max_unavailable           = null              # optional
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | GKE cluster ID |
| `cluster_name` | GKE cluster name |
| `cluster_endpoint` | Cluster endpoint IP |
| `cluster_master_version` | Master Kubernetes version |
| `node_pool_names` | List of node pool names |
| `workload_pool` | Workload Identity pool (`{project}.svc.id.goog`) |

## Workload Identity

Workload Identity is enabled by default. To use GCP services from pods:

1. Create a GCP service account:
```hcl
resource "google_service_account" " workloads" {
  project = "my-project"
  account_id = "my-app-sa"
}
```

2. Bind it to a Kubernetes service account:
```hcl
module "gke_iam" {
  source = "../../modules/gcp/iam"

  project = "my-project"

  service_accounts = {
    "my-namespace/my-app" = {
      email   = google_service_account.workloads.email
      display_name = "My App SA"
    }
  }
}
```

3. Annotate the Kubernetes service account:
```yaml
metadata:
  annotations:
    iam.gke.io/gcp-service-account: my-app-sa@my-project.iam.gserviceaccount.com
```

## Security Features

| Feature | Description |
|---------|-------------|
| Shielded Nodes | Secure boot, integrity monitoring, vTPM |
| Private Nodes | No public IPs, VPC-native |
| Network Policy | Calico-style pod segmentation |
| Binary Authorization | Deploy only signed images |
| Database Encryption | CMEK for etcd data at rest |
| Workload Identity | Pods impersonate GCP service accounts |

## Autoscaling

Node pools support both cluster autoscaler and manual configuration:

- Set `min_node_count` and `max_node_count` for cluster autoscaler
- Set `node_count` for fixed-size pools
- Use `preemptible` for cost savings (up to 80% discount)

## GKE Versions

The module uses the default GKE version for the channel. Pin specific versions
via the GCP console or gcloud for production control.
