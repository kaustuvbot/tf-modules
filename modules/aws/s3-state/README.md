# AWS S3 State Module

Provisions an S3 bucket for Terraform remote state storage with versioning, server-side encryption, and public access fully blocked.

## Usage

```hcl
module "state" {
  source = "../../modules/aws/s3-state"

  bucket_name = "tf-state-myproject-prod"
  kms_key_arn = module.kms.state_key_arn   # optional: use CMK instead of AES256
  tags = {
    Project     = "myproject"
    Environment = "prod"
  }
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `bucket_name` | `string` | — | Name of the S3 bucket |
| `force_destroy` | `bool` | `false` | Allow deletion even with objects (dev only) |
| `kms_key_arn` | `string` | `null` | KMS CMK ARN for SSE-KMS; falls back to AES256 if null |
| `access_log_bucket` | `string` | `null` | Target bucket for S3 access logs |
| `access_log_prefix` | `string` | `"s3-access-logs/"` | Prefix for access log objects |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | Bucket name (same as `bucket_name`) |
| `bucket_arn` | ARN of the created bucket |
| `bucket_name` | Name of the created bucket |

## Notes

- Versioning is always enabled — required for state history and recovery.
- `prevent_destroy = true` is set in the lifecycle block to guard against `terraform destroy`.
- Pair with the `dynamodb-lock` module and the `kms` module for a complete, hardened remote state backend.
