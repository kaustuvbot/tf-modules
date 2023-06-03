# GitHub OIDC for AWS — Setup and Troubleshooting

## Overview

This project uses GitHub Actions OIDC federation to authenticate with AWS. No static access keys are stored in GitHub — instead, workflows request short-lived credentials via `sts:AssumeRoleWithWebIdentity`.

## How It Works

1. GitHub Actions generates a signed JWT for each workflow run
2. The JWT contains claims: repository, branch, actor, workflow, etc.
3. AWS verifies the JWT against the registered OIDC provider
4. If trust policy conditions match, AWS issues temporary credentials

## Setup Steps

### 1. Deploy the IAM module

```hcl
module "iam" {
  source = "../../modules/aws/iam"

  project              = "myproject"
  environment          = "prod"
  github_org           = "my-org"
  github_repositories  = ["my-org/infra-repo"]
}
```

### 2. Configure GitHub Actions workflow

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_PLAN_ROLE_ARN }}
      aws-region: us-east-1
```

### 3. Store role ARNs in GitHub Secrets

- `AWS_PLAN_ROLE_ARN` — from `module.iam.plan_role_arn`
- `AWS_APPLY_ROLE_ARN` — from `module.iam.apply_role_arn`

## Trust Policy Reference

### Plan role (any branch/PR)

```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:my-org/infra-repo:*"
    }
  }
}
```

### Apply role (main branch only)

```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub": "repo:my-org/infra-repo:ref:refs/heads/main"
    }
  }
}
```

## Troubleshooting

### "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Cause**: The JWT `sub` claim doesn't match the trust policy condition.

**Check**:
- Is the repository name correct in `github_repositories`?
- For the apply role: is the workflow running on the correct branch?
- Is `permissions.id-token: write` set in the workflow?

### "No OpenIDConnect provider found"

**Cause**: The OIDC provider hasn't been created yet, or it's in a different AWS account.

**Fix**: Run `terraform apply` for the IAM module first.

### "Audience not allowed"

**Cause**: The `aud` claim doesn't match `sts.amazonaws.com`.

**Check**: Ensure `configure-aws-credentials` action uses the default audience, or that you haven't overridden `audience` in the action config.

### Session expires mid-apply

**Cause**: Default session is 1 hour. Large applies may exceed this.

**Fix**: Increase `max_session_duration` (up to 12 hours / 43200 seconds).

## Security Considerations

- **Rotate thumbprints**: GitHub occasionally rotates their OIDC signing certificates. The `tls_certificate` data source fetches the current thumbprint on each plan.
- **Permissions boundaries**: Use `permissions_boundary_arn` in production to cap what the apply role can do, even with PowerUserAccess.
- **Branch protection**: The apply role's branch restriction is only as strong as your GitHub branch protection rules. Ensure `main` requires PR reviews and status checks.
