# AWS Security Baseline

## Overview

This platform implements a security baseline covering audit logging, encryption, and configuration monitoring. All security features are opt-in via module variables, allowing gradual rollout per environment.

## What's Enabled

### CloudTrail

| Setting | Value | Why |
|---------|-------|-----|
| Multi-region | Yes | Captures API calls across all regions |
| Global events | Yes | Includes IAM, STS, CloudFront events |
| Log file validation | Yes | Detects tampering with log files |
| CloudWatch integration | Yes | Enables real-time alerting on API events |
| S3 delivery | Yes | Long-term storage with lifecycle policies |
| KMS encryption | Optional | Encrypts logs at rest with customer-managed key |

### AWS Config

| Setting | Value | Why |
|---------|-------|-----|
| All resource types | Yes | Records configuration for every AWS resource |
| Global resources | Yes | Includes IAM users, roles, policies |
| Snapshot frequency | 6 hours | Balance between freshness and cost |
| S3 delivery | Yes | Configuration history stored long-term |

### KMS

| Key | Purpose | Rotation | Key Policy |
|-----|---------|----------|------------|
| Logs key | CloudWatch, CloudTrail, S3 log bucket | Annual (automatic) | Root + CloudWatch + CloudTrail services |
| State key | Terraform state S3 bucket | Annual (automatic) | Root account only |
| General key | Other services as needed | Annual (automatic) | Root account only |

### IAM/OIDC

| Setting | Value | Why |
|---------|-------|-----|
| Authentication | OIDC federation | No long-lived credentials |
| Plan role | ReadOnlyAccess | Safe for PR pipelines |
| Apply role | PowerUserAccess + branch restriction | Only main branch can apply |
| Session duration | 1 hour (configurable) | Limits blast radius of leaked tokens |
| Permissions boundary | Optional | Caps effective permissions per environment |

## S3 Log Bucket Security

- Public access: Fully blocked (all four block settings enabled)
- Encryption: AES256 by default, KMS optional
- Versioning: Enabled (audit trail for log modifications)
- Lifecycle: Transition to IA at 30 days, Glacier at 60, expire at retention period

## Current Limitations

1. **No Config Rules yet**: Config recorder is enabled but no managed rules are deployed. Rules will be added in a future batch.
2. **Single-account scope**: CloudTrail is not configured as an organization trail. Multi-account support is a future enhancement.
3. **No GuardDuty**: Threat detection will be added in Phase 4 (commits 104–105).
4. **No Security Hub**: Compliance standards (CIS, PCI) will be enabled in Phase 4.
5. **KMS key policies are broad**: Root account has full access. Per-service grants will be tightened in Phase 4.

## How to Enable

```hcl
module "kms" {
  source = "../../modules/aws/kms"

  project     = "myproject"
  environment = "prod"
}

module "logging" {
  source = "../../modules/aws/logging"

  project          = "myproject"
  environment      = "prod"
  enable_cloudtrail = true
  enable_config     = true
  kms_key_arn      = module.kms.logs_key_arn
}
```

## Security Scanning in CI

The CI pipeline runs tfsec and checkov on every PR (soft-fail mode during rollout). See [CI/CD docs](ci-cd.md#security-scanning) for suppression and configuration details.
