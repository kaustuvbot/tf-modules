# AWS Logging Module

Central logging infrastructure for the platform. Manages a CloudWatch log group, an S3 log delivery bucket, and optionally CloudTrail, AWS Config, and GuardDuty.

## Usage

```hcl
module "logging" {
  source = "../../modules/aws/logging"

  project     = "myproject"
  environment = "prod"

  enable_cloudtrail = true
  enable_config     = true
  enable_guardduty  = true

  kms_key_arn       = module.kms.logs_key_arn
  retention_in_days = 365

  tags = {
    CostCenter = "platform"
  }
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name for naming and tagging |
| `environment` | `string` | — | Environment (`dev`, `staging`, `prod`) |
| `retention_in_days` | `number` | `90` | CloudWatch log group retention (must be a valid CW value) |
| `enable_cloudtrail` | `bool` | `false` | Create a multi-region CloudTrail trail |
| `enable_config` | `bool` | `false` | Enable AWS Config recorder and delivery channel |
| `enable_guardduty` | `bool` | `false` | Enable GuardDuty threat detection detector |
| `kms_key_arn` | `string` | `null` | KMS key for CloudWatch and CloudTrail encryption |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `log_group_name` | Name of the central CloudWatch log group |
| `log_group_arn` | ARN of the central CloudWatch log group |
| `log_bucket_id` | S3 log delivery bucket name |
| `log_bucket_arn` | S3 log delivery bucket ARN |
| `cloudtrail_arn` | ARN of the CloudTrail trail (null if disabled) |
| `config_recorder_id` | AWS Config recorder ID (null if disabled) |
| `guardduty_detector_id` | GuardDuty detector ID (null if disabled) |

## Notes

- The S3 log bucket has lifecycle rules: transition to STANDARD_IA after 30 days, GLACIER after 60 days, expire after `retention_in_days`.
- CloudTrail is configured as multi-region with log file validation and CloudWatch Logs delivery.
- GuardDuty only manages the detector resource. Findings are available in the AWS Console and EventBridge. For alerting, wire findings to an SNS topic via EventBridge rules.
