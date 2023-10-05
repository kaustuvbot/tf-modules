# GCP VPC Network Module

Manages a Google Cloud VPC network with custom subnets, secondary ranges,
Cloud NAT for private egress, and Private Service Access for managed services.

## Usage

### Basic VPC with Subnets

```hcl
module "vpc" {
  source = "../../modules/gcp/vpc-network"

  project     = "myproject"
  environment = "prod"

  subnets = {
    "us-central1" = {
      region             = "us-central1"
      ip_cidr_range    = "10.0.1.0/24"
      private_ip_google_access = true
    }
    "us-east1" = {
      region          = "us-east1"
      ip_cidr_range = "10.0.2.0/24"
    }
  }
}
```

### VPC with GKE Secondary Ranges

```hcl
module "vpc_gke" {
  source = "../../modules/gcp/vpc-network"

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
  nat_region       = "us-central1"
}
```

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `project` | `string` | Project ID |
| `environment` | `string` | Environment: `dev`, `staging`, or `prod` |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `routing_mode` | `string` | `REGIONAL` | `REGIONAL` or `GLOBAL` |
| `mtu` | `number` | `1460` | MTU for the VPC |
| `subnets` | `map(object)` | `{}` | Map of subnet configs (see below) |
| `enable_cloud_nat` | `bool` | `false` | Enable Cloud NAT |
| `nat_region` | `string` | `us-central1` | Region for NAT |
| `nat_ip_allocate_option` | `string` | `AUTO_ONLY` | `AUTO_ONLY` or `MANUAL_ONLY` |
| `nat_ips` | `list(string)` | `[]` | NAT IPs for MANUAL_ONLY |
| `enable_nat_logging` | `bool` | `false` | Enable NAT logs |
| `bgp_asn` | `number` | `64514` | BGP AS number |
| `enable_private_service_access` | `bool` | `false` | Enable PSA |
| `labels` | `map(string)` | `{}` | Additional labels |

### subnets object shape

```hcl
subnets = {
  "us-central1" = {
    region                     = "us-central1"  # required
    ip_cidr_range            = "10.0.1.0/24"  # required
    private_ip_google_access = true             # optional, default false
    secondary_ranges         = {                 # optional, for GKE
      "pods"     = "10.1.0.0/16"
      "services" = "10.2.0.0/16"
    }
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `network_id` | ID of the VPC network |
| `network_name` | Name of the VPC network |
| `network_self_link` | Self link of the VPC network |
| `subnet_ids` | Map of subnet name to ID |
| `subnet_ips` | Map of subnet name to IP CIDR range |

## Architecture

```
┌─────────────────────────────────────────┐
│           VPC Network                   │
│           10.0.0.0/16                  │
└─────────────────────────────────────────┘
         │                    │
    ┌────▼────┐         ┌───▼─────┐
    │ us-c1  │         │ us-e1  │
    │ 10.0.1 │         │ 10.0.2 │
    └─────────┘         └─────────┘
         │
    ┌────▼────────┐
    │ Cloud NAT   │
    │ (egress)    │
    └─────────────┘
         │
    ┌────▼────────────┐
    │ Private Service │
    │ Access          │
    └─────────────────┘
         │
    ┌────▼────────────┐
    │ Cloud SQL      │
    │ GKE Pods       │
    │ Cloud Memorystore
    └─────────────────┘
```

## Security Notes

- Use `private_ip_google_access = true` on subnets needing GCP API access without NAT.
- Cloud NAT is required for private subnets to reach the internet.
- Secondary ranges must not overlap with primary CIDR or other secondaries.
- Private Service Access enables private connectivity to GCP managed services.
