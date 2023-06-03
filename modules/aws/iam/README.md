# AWS IAM Module

Manages GitHub OIDC federation and least-privilege CI/CD roles for Terraform automation.

## Features

- GitHub Actions OIDC identity provider (no long-lived credentials)
- Separate plan (read-only) and apply (read-write) roles
- Apply role restricted to default branch only
- Optional permissions boundary support
- Configurable session duration

## Usage

```hcl
module "iam" {
  source = "../../modules/aws/iam"

  project     = "myproject"
  environment = "prod"

  github_org          = "my-org"
  github_repositories = ["my-org/infra-repo"]
  apply_branch        = "main"

  # Optional: restrict role capabilities
  permissions_boundary_arn = aws_iam_policy.boundary.arn
  max_session_duration     = 3600

  tags = {
    Team = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project` | Project name for naming and tagging | `string` | — | yes |
| `environment` | Environment name (dev, staging, prod) | `string` | — | yes |
| `github_org` | GitHub organization or username | `string` | — | yes |
| `github_repositories` | Repos allowed to assume CI roles | `list(string)` | — | yes |
| `apply_branch` | Branch restricted for apply role | `string` | `"main"` | no |
| `max_session_duration` | Max session duration in seconds | `number` | `3600` | no |
| `permissions_boundary_arn` | IAM policy ARN for permissions boundary | `string` | `null` | no |
| `tags` | Additional tags for IAM resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `oidc_provider_arn` | ARN of the GitHub OIDC provider |
| `oidc_provider_url` | URL of the GitHub OIDC provider |
| `plan_role_arn` | ARN of the CI plan role |
| `plan_role_name` | Name of the CI plan role |
| `apply_role_arn` | ARN of the CI apply role |
| `apply_role_name` | Name of the CI apply role |

## Design Decisions

1. **OIDC over static keys**: Federated identity eliminates credential rotation burden.
2. **Role separation**: Plan role can run on any PR; apply role only runs on the default branch.
3. **StringEquals for apply**: The apply trust policy uses exact match on branch ref, not wildcard.
4. **PowerUserAccess for apply**: Intentionally broad — scope down with permissions boundaries per environment.
