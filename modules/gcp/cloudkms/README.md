# GCP CloudKMS Module

Manages a Google Cloud KMS key ring and crypto key with rotation, IAM bindings,
and protection levels.

## Usage

### Basic Key with Rotation

```hcl
module "kms" {
  source = "../../modules/gcp/cloudkms"

  project      = "my-project"
  environment = "prod"
  location    = "global"

  rotation_period = "7776000s"  # 90 days

  key_admin_service_accounts = [
    "terraform@my-project.iam.gserviceaccount.com"
  ]

  labels = {
    team = "security"
  }
}
```

### HSM-Backed Key with Viewer

```hcl
module "kms_hsm" {
  source = "../../modules/gcp/cloudkms"

  project      = "my-project"
  environment = "prod"
  location    = "global"

  protection_level = "HSM"
  key_algorithm   = "RSA_OAEP_3072_SHA256"

  rotation_period = "2592000s"  # 30 days

  key_admin_service_accounts = [
    "admin@my-project.iam.gserviceaccount.com"
  ]

  key_viewer_service_accounts = [
    "auditor@my-project.iam.gserviceaccount.com"
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
| `location` | `string` | `global` | GCP region for key ring |
| `rotation_period` | `string` | `7776000s` | Key rotation period |
| `key_algorithm` | `string` | `GOOGLE_SYMMETRIC_ENCRYPTION` | Key algorithm |
| `protection_level` | `string` | `SOFTWARE` | Protection level (`SOFTWARE` or `HSM`) |
| `key_admin_service_accounts` | `list(string)` | `[]` | Service accounts with encrypter/decrypter role |
| `key_viewer_service_accounts` | `list(string)` | `[]` | Service accounts with viewer role |
| `labels` | `map(string)` | `{}` | Additional labels |

## Outputs

| Name | Description |
|------|-------------|
| `key_ring_id` | ID of the KMS key ring |
| `crypto_key_id` | ID of the KMS crypto key |
| `crypto_key_name` | Name of the KMS crypto key |
| `crypto_key_self_link` | Self link of the KMS crypto key |

## Key Algorithms

| Algorithm | Use Case |
|-----------|----------|
| `GOOGLE_SYMMETRIC_ENCRYPTION` | Default, symmetric encryption |
| `RSA_OAEP_3072_SHA256` | Asymmetric, 3072-bit key |
| `RSA_OAEP_4096_SHA256` | Asymmetric, 4096-bit key |
| `EC_SIGN_P256_SHA256` | Elliptic curve, P-256 |
| `EC_SIGN_P384_SHA384` | Elliptic curve, P-384 |

## Protection Levels

| Level | Description |
|-------|-------------|
| `SOFTWARE` | Keys stored in software (lower cost) |
| `HSM` | Keys stored in hardware security module (FIPS 140-2 Level 3) |

## Rotation

The module configures automatic key rotation at the specified interval. New key
versions are created automatically. Old versions remain for decryption.

- 90 days: Standard for most use cases
- 30 days: High-security environments
- 365 days: Low-frequency key rotation

## IAM

Grant access to the key via service account email addresses:

```hcl
key_admin_service_accounts = [
  "my-sa@my-project.iam.gserviceaccount.com"
]
```

Roles applied:
- `roles/cloudkms.cryptoKeyEncrypterDecrypter` — encrypt/decrypt
- `roles/cloudkms.viewer` — read-only access

## Security Notes

- HSM keys cannot be exported — use for high-value encryption
- Enable rotation to limit exposure from key compromise
- Use separate keys per environment for isolation
- `prevent_destroy` lifecycle is enabled — key deletion requires Terraform state manipulation
