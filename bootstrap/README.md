# Bootstrap — Terraform State Backend

This directory bootstraps the AWS infrastructure needed for Terraform remote state:

- **S3 bucket** — versioned, encrypted state storage
- **DynamoDB table** — state locking to prevent concurrent modifications

## Quick Start

```bash
terraform init
terraform apply -var="project=tfmodules" -var="region=us-east-1"
```

## What Gets Created

| Resource | Name Pattern |
|----------|-------------|
| S3 Bucket | `<project>-terraform-state-<region>` |
| DynamoDB Table | `<project>-terraform-lock` |

## Next Steps

After bootstrapping, configure the S3 backend in your environment directories. See the full guide at [docs/aws-backend.md](../docs/aws-backend.md).
