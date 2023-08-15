# AWS DynamoDB Lock Module

Provisions a DynamoDB table for Terraform remote state locking. Uses `PAY_PER_REQUEST` billing to minimise cost on a low-traffic table.

## Usage

```hcl
module "lock" {
  source = "../../modules/aws/dynamodb-lock"

  table_name                = "tf-state-lock-myproject"
  enable_delete_protection  = true   # recommended in prod
  tags = {
    Project     = "myproject"
    Environment = "prod"
  }
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `table_name` | `string` | — | Name of the DynamoDB lock table |
| `enable_ttl` | `bool` | `false` | Enable TTL to auto-expire stale lock entries |
| `ttl_attribute` | `string` | `"ExpiresAt"` | Attribute name used for TTL (requires `enable_ttl = true`) |
| `enable_delete_protection` | `bool` | `false` | Prevent accidental table deletion; set `true` in prod |
| `tags` | `map(string)` | `{}` | Additional tags to merge onto the table |

## Outputs

| Name | Description |
|------|-------------|
| `table_name` | Name of the created DynamoDB table |
| `table_arn` | ARN of the created DynamoDB table |

## Notes

- The hash key is always `LockID` — this is required by the Terraform S3 backend.
- `enable_delete_protection = true` is recommended for production. Disable it before running `terraform destroy`.
- Pair with the `s3-state` module for a complete remote state backend.
