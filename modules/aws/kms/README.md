# AWS KMS Module

Provisions baseline KMS customer managed keys (CMKs) for platform-wide encryption. Manages up to three keys: logs, state, and general-purpose.

## Usage

```hcl
module "kms" {
  source = "../../modules/aws/kms"

  project     = "myproject"
  environment = "prod"

  enable_logs_key    = true
  enable_state_key   = true
  enable_general_key = false

  deletion_window_in_days = 30
  enable_key_rotation     = true
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name for naming and tagging |
| `environment` | `string` | — | Environment (`dev`, `staging`, `prod`) |
| `enable_logs_key` | `bool` | `true` | Create a key for CloudWatch/CloudTrail/S3 log encryption |
| `enable_state_key` | `bool` | `true` | Create a key for Terraform state encryption |
| `enable_general_key` | `bool` | `false` | Create a general-purpose key |
| `deletion_window_in_days` | `number` | `30` | Key deletion pending window (7–30 days) |
| `enable_key_rotation` | `bool` | `true` | Enable automatic annual key rotation on all keys |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `logs_key_arn` | ARN of the logs KMS key |
| `logs_key_id` | ID of the logs KMS key |
| `logs_key_alias` | Alias of the logs KMS key |
| `state_key_arn` | ARN of the state KMS key |
| `state_key_id` | ID of the state KMS key |
| `state_key_alias` | Alias of the state KMS key |
| `general_key_arn` | ARN of the general KMS key |
| `general_key_id` | ID of the general KMS key |
| `general_key_alias` | Alias of the general KMS key |

## Notes

- The logs key policy allows CloudWatch Logs and CloudTrail service principals.
- Keys are disabled by default when their `enable_*` flag is `false` — outputs return `null`.
- Pass `state_key_arn` into the `s3-state` module's `kms_key_arn` for end-to-end state encryption.
