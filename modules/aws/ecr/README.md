# AWS ECR Module

Creates one or more Amazon ECR repositories from a map input. Each repository
has image scanning on push, a lifecycle policy for cost control, and optional
KMS encryption.

## Usage

```hcl
module "ecr" {
  source = "../../modules/aws/ecr"

  project     = "myapp"
  environment = "prod"

  repositories = {
    api = {
      image_tag_mutability = "IMMUTABLE"
      scan_on_push         = true
      untagged_expiry_days = 7
      tagged_keep_count    = 50
    }
    worker = {}  # uses all defaults
  }
}
```

Repository names follow the `<project>/<environment>/<name>` path convention:

```
myapp/prod/api
myapp/prod/worker
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name (2-32 chars) |
| `environment` | `string` | — | Environment: dev, staging, prod |
| `repositories` | `map(object)` | — | Repository configurations (see below) |
| `tags` | `map(string)` | `{}` | Additional tags |

### `repositories` object shape

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `image_tag_mutability` | `string` | `"MUTABLE"` | `MUTABLE` or `IMMUTABLE` |
| `scan_on_push` | `bool` | `true` | Enable basic image scanning on push |
| `untagged_expiry_days` | `number` | `14` | Days before untagged images are expired |
| `tagged_keep_count` | `number` | `30` | Maximum number of tagged images to retain |
| `kms_key_arn` | `string` | `null` | KMS key ARN for encryption (AES-256 used when null) |

## Outputs

| Name | Description |
|------|-------------|
| `repository_urls` | Map of name → full ECR repository URL |
| `repository_arns` | Map of name → repository ARN |
| `registry_id` | AWS account ID owning the registry |

## Image Tag Mutability

Use `IMMUTABLE` in production to prevent tag overwrites (immutable tags are
a supply chain security best practice — a `v1.2.3` push cannot overwrite an
existing `v1.2.3` image). Use `MUTABLE` in development for rapid iteration.

## Lifecycle Policy

Each repository gets two lifecycle rules:

1. **Untagged images**: Expired after `untagged_expiry_days` days (default 14).
   Build cache layers and dangling images are automatically removed.

2. **Tagged images**: The most recent `tagged_keep_count` images matching
   `v*`, `sha-*`, or `release-*` prefixes are retained. Older images are
   expired automatically.

## KMS Encryption

```hcl
repositories = {
  api = {
    kms_key_arn = module.kms.general_key_arn
  }
}
```

When `kms_key_arn` is null, ECR uses AES-256 server-side encryption managed
by AWS (no cost, no configuration required).

## IAM Push/Pull Access

```hcl
# Allow a CI role to push images
data "aws_iam_policy_document" "ecr_push" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = values(module.ecr.repository_arns)
  }
}
```

## Cross-Account Pull

To allow another account to pull images, attach a repository policy:

```hcl
resource "aws_ecr_repository_policy" "cross_account" {
  for_each   = module.ecr.repository_arns
  repository = split("/", each.value)[length(split("/", each.value)) - 1]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.consumer_account_id}:root" }
      Action    = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    }]
  })
}
```
