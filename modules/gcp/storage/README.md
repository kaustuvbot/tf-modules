# GCP Storage Module

Manages a Google Cloud Storage bucket with versioning, lifecycle rules, KMS
encryption, retention policy, and IAM bindings.

## Usage

### Basic Bucket

```hcl
module "storage" {
  source = "../../modules/gcp/storage"

  project      = "my-project"
  environment = "prod"
  location    = "US"

  versioning_enabled = true
  bucket_name_suffix = "data"

  labels = {
    team = "platform"
  }
}
```

### Bucket with Lifecycle Rules and Encryption

```hcl
module "storage_compliance" {
  source = "../../modules/gcp/storage"

  project      = "my-project"
  environment = "prod"
  location    = "US"

  bucket_name_suffix = "archive"

  versioning_enabled              = true
  uniform_bucket_level_access    = true

  lifecycle_rules = [
    {
      action_type    = "SetStorageClass"
      storage_class = "NEARLINE"
      age           = 30
    },
    {
      action_type    = "SetStorageClass"
      storage_class = "COLDLINE"
      age           = 90
    },
    {
      action_type    = "Delete"
      age           = 365
    }
  ]

  kms_key_name = module.kms.crypto_key_id

  retention_period_days = 2555  # 7 years
  retention_policy_locked = true

  viewer_members = [
    "group:platform@my-project.iam.gserviceaccount.com"
  ]
}
```

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `project` | `string` | GCP project ID |
| `environment` | `string` | Environment: `dev`, `staging`, or `prod` |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `bucket_name_suffix` | `string` | `bucket` | Bucket name suffix |
| `location` | `string` | `US` | GCP region |
| `storage_class` | `string` | `STANDARD` | Default storage class |
| `versioning_enabled` | `bool` | `true` | Enable object versioning |
| `uniform_bucket_level_access` | `bool` | `true` | Enforce uniform bucket-level access |
| `lifecycle_rules` | `list(object)` | `[]` | Lifecycle rules |
| `kms_key_name` | `string` | `null` | KMS key for encryption |
| `retention_period_days` | `number` | `null` | Object retention period |
| `retention_policy_locked` | `bool` | `false` | Lock retention policy |
| `viewer_members` | `list(string)` | `[]` | Members with objectViewer role |
| `editor_members` | `list(string)` | `[]` | Members with objectAdmin role |
| `labels` | `map(string)` | `{}` | Additional labels |

### lifecycle_rules object shape

```hcl
lifecycle_rules = [{
  action_type        = "SetStorageClass"  # or "Delete"
  storage_class     = "NEARLINE"           # optional, for SetStorageClass
  age               = 30                   # optional, days before action
  created_before    = null                  # optional, ISO date
  is_live         = null                  # optional, bool
  matches_prefix   = []                    # optional, list of prefixes
  matches_suffix   = []                    # optional, list of suffixes
  num_newer_versions = null               # optional, number
}]
```

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the GCS bucket |
| `bucket_url` | URL of the GCS bucket (`gs://...`) |
| `bucket_id` | ID of the GCS bucket |
| `bucket_self_link` | Self link of the GCS bucket |

## Storage Classes

| Class | Use Case |
|-------|----------|
| `STANDARD` | Frequent access (default) |
| `NEARLINE` | Infrequent access (< once/month) |
| `COLDLINE` | Rare access (< once/year) |
| `ARCHIVE` | Long-term archive (> once/year) |

## Lifecycle Rules

Common lifecycle configurations:

1. **Cost Optimization**: Move to cheaper storage after N days
2. **Compliance**: Retain data for legal requirements
3. **Versioning**: Keep N versions of objects
4. **Cleanup**: Delete old temporary files

## Retention Policy

When `retention_period_days` is set:
- Objects cannot be deleted until retention period expires
- Set `retention_policy_locked = true` to prevent policy changes
- Locked policies require customer support to unlock

## IAM

Grant access using GCP principal formats:

```hcl
viewer_members = [
  "group:team@domain.com",
  "user:user@domain.com",
  "serviceAccount:sa@project.iam.gserviceaccount.com"
]
```

## Security Notes

- `uniform_bucket_level_access = true` disables ACLs — use IAM for all access control
- Enable versioning to protect against accidental deletion
- Use KMS encryption for sensitive data
- Lock retention policy for compliance requirements
- Public access is disabled by default
