# GCP IAM Module

Manages GCP service accounts, project IAM bindings, and Workload Identity
configuration for GKE integration.

## Usage

### Basic Service Accounts

```hcl
module "iam" {
  source = "../../modules/gcp/iam"

  project     = "myproject"
  environment = "prod"

  service_accounts = {
    "app" = {
      display_name = "Application Service Account"
      description = "Runs the application workload"
    }
  }
}
```

### Service Accounts with Project Roles

```hcl
module "iam" {
  source = "../../modules/gcp/iam"

  project     = "myproject"
  environment = "prod"

  service_accounts = {
    "app" = {
      display_name = "Application SA"
    }
    "database" = {
      display_name = "Database SA"
    }
  }

  project_roles = {
    "app-storage" = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:app-myproject-prod@myproject.iam.gserviceaccount.com"
    }
    "database-pubsub" = {
      role   = "roles/pubsub.subscriber"
      member = "serviceAccount:database-myproject-prod@myproject.iam.gserviceaccount.com"
    }
  }
}
```

### Workload Identity for GKE

```hcl
module "iam" {
  source = "../../modules/gcp/iam"

  project     = "myproject"
  environment = "prod"

  service_accounts = {
    "app" = {
      display_name = "Application SA"
    }
  }

  workload_identity_enabled = true
  workload_identity_pool   = "app-pool"
  service_accounts_keys   = ["app"]

  project_roles = {
    "app-gcs" = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:app-myproject-prod@myproject.iam.gserviceaccount.com"
    }
  }
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
| `service_accounts` | `map(object)` | `{}` | Service accounts to create |
| `project_roles` | `map(object)` | `{}` | Project IAM member bindings |
| `project_bindings` | `map(object)` | `{}` | Project IAM bindings (multiple members) |
| `workload_identity_enabled` | `bool` | `false` | Enable Workload Identity |
| `workload_identity_pool` | `string` | `default-pool` | Workload Identity pool name |
| `service_accounts_keys` | `list(string)` | `[]` | SAs to grant WI access |
| `labels` | `map(string)` | `{}` | Additional labels |

### service_accounts object shape

```hcl
service_accounts = {
  "app" = {
    display_name = "Application SA"  # required
    description  = "App workload"    # optional
  }
}
```

### project_roles object shape

```hcl
project_roles = {
  "name" = {
    role   = "roles/storage.objectViewer"                    # required
    member = "serviceAccount:sa@project.iam.gserviceaccount.com"  # required
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `service_account_emails` | Map of SA name to email |
| `service_account_ids` | Map of SA name to unique ID |

## Workload Identity

Workload Identity allows Kubernetes service accounts to impersonate GCP service
accounts without exposing credentials.

### Setup

1. Enable Workload Identity on the GKE cluster (automatic in `gcp/gke` module)
2. Create a Kubernetes service account in your namespace
3. Grant the GCP SA to the KSA using this module

### Example

```yaml
# Kubernetes deployment
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
  annotations:
    iam.gke.io/gcp-service-account: app-myproject-prod@myproject.iam.gserviceaccount.com
```

The annotation tells GKE to use Workload Identity to impersonate the GCP SA.

## Security Best Practices

- Use Workload Identity instead of downloading service account keys.
- Follow principle of least privilege — grant specific roles, not broad ones.
- Use separate service accounts for different workloads.
- Enable Audit Logs to track IAM changes.
