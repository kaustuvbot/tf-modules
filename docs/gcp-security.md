# GCP Security Guide

Security hardening guide for GCP resources in this repository.

## GKE Security

### Private Cluster

Enable private nodes and endpoint:

```hcl
module "gke" {
  # ...
  enable_private_nodes    = true
  enable_private_endpoint = true
}
```

Private clusters:
- Nodes have no public IPs
- Control plane is accessible only via private IP
- Requires VPC with Cloud NAT for internet access

### Workload Identity

Use Workload Identity instead of service account keys:

```hcl
module "gke" {
  # ...
  workload_identity_enabled = true
}
```

Grant access from Kubernetes:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
  annotations:
    iam.gke.io/gcp-service-account: my-sa@my-project.iam.gserviceaccount.com
```

### Shielded Nodes

Enable Shielded Nodes for node integrity:

```hcl
module "gke" {
  # ...
  enable_shielded_nodes = true
}
```

Features:
- Secure Boot: blocks unsigned workloads
- vTPM: trusted platform module
- Integrity Monitoring: detects boot-level compromises

### Network Policy

Enable Calico network policies:

```hcl
module "gke" {
  # ...
  enable_network_policy = true
}
```

### Binary Authorization

Enforce signed images only:

```hcl
module "gke" {
  # ...
  enable_binary_authorization = true
}
```

### Database Encryption

Enable CMEK for etcd:

```hcl
module "gke" {
  # ...
  enable_database_encryption = true
  database_encryption_key   = module.kms.crypto_key_id
}
```

## Cloud KMS

### Key Rotation

Enable automatic key rotation:

```hcl
module "kms" {
  # ...
  rotation_period = "7776000s"  # 90 days
}
```

### HSM Keys

Use HSM for high-value encryption:

```hcl
module "kms" {
  # ...
  protection_level = "HSM"
}
```

HSM keys are FIPS 140-2 Level 3 compliant and cannot be exported.

## Cloud Storage

### Uniform Bucket-Level Access

Disable ACLs and use IAM only:

```hcl
module "storage" {
  # ...
  uniform_bucket_level_access = true
}
```

### Encryption

Use KMS encryption:

```hcl
module "storage" {
  # ...
  kms_key_name = module.kms.crypto_key_id
}
```

### Retention

Lock retention for compliance:

```hcl
module "storage" {
  # ...
  retention_period_days = 2555  # 7 years
  retention_policy_locked = true
}
```

## VPC Network

### Private Google Access

Enable private Google access for private workloads:

```hcl
module "vpc" {
  # ...
  enable_private_google_access = true
}
```

### Cloud NAT

Use Cloud NAT for egress:

```hcl
module "vpc" {
  # ...
  enable_cloud_nat = true
}
```

## IAM

### Service Accounts

Create service accounts per application:

```hcl
module "iam" {
  service_accounts = {
    "app-name" = {
      display_name = "App Name SA"
    }
  }
}
```

### Workload Identity Pool

Grant access via Workload Identity:

```hcl
resource "google_service_account" "app" {
  project = var.project
  account_id = "app-sa"
}

resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.app.name
  role              = "roles/iam.workloadIdentityUser"
  member            = "serviceAccount:${var.project}.svc.id.goog/ns/${var.namespace}/${var.k8s_sa}"
}
```

## Best Practices

1. **Use Workload Identity** — never download service account keys
2. **Enable private endpoints** — reduce attack surface
3. **Use Shielded Nodes** — protect node integrity
4. **Enable audit logging** — Cloud Audit Logs for compliance
5. **Use VPC Service Controls** — perimeter security for sensitive data
6. **Enable Security Command Center** — centralized security visibility
