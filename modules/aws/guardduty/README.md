# AWS GuardDuty Module

Manages an AWS GuardDuty detector with EKS audit log analysis, S3 data events,
optional malware protection, and S3 findings export.

## Usage

### Basic GuardDuty with EKS Monitoring

```hcl
module "guardduty" {
  source = "../../modules/aws/guardduty"

  project     = "myapp"
  environment = "prod"

  enable_kubernetes_logs = true

  tags = {
    Team = "security"
  }
}
```

### GuardDuty with S3 Events and Malware Protection

```hcl
module "guardduty_full" {
  source = "../../modules/aws/guardduty"

  project     = "myapp"
  environment = "prod"

  enable_kubernetes_logs    = true
  enable_s3_logs           = true
  enable_malware_protection = true

  findings_s3_bucket_arn = aws_s3_bucket.guardduty_findings.arn
  findings_s3_kms_key_arn = aws_kms_key.guardduty.arn

  tags = {
    Team = "security"
  }
}
```

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `project` | `string` | Project name |
| `environment` | `string` | Environment: `dev`, `staging`, or `prod` |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_s3_logs` | `bool` | `false` | Enable S3 data event protection in GuardDuty |
| `enable_kubernetes_logs` | `bool` | `true` | Enable EKS audit log analysis in GuardDuty |
| `enable_malware_protection` | `bool` | `false` | Enable GuardDuty Malware Protection for EC2 and EBS |
| `findings_s3_bucket_arn` | `string` | `null` | ARN of S3 bucket to export GuardDuty findings |
| `findings_s3_kms_key_arn` | `string` | `null` | KMS key ARN for encrypting exported findings |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `detector_id` | GuardDuty detector ID |
| `detector_arn` | GuardDuty detector ARN |

## Data Sources

GuardDuty monitors:

| Source | Description | Enable Flag |
|--------|-------------|-------------|
| VPC Flow Logs | Network traffic analysis | Always on |
| CloudTrail | API call analysis | Always on |
| DNS Logs | DNS query analysis | Always on |
| EKS Audit Logs | Kubernetes API audit events | `enable_kubernetes_logs` |
| S3 Data Events | S3 object access logs | `enable_s3_logs` |
| Malware Protection | EBS volume scanning | `enable_malware_protection` |

## EKS Audit Log Monitoring

When `enable_kubernetes_logs = true`, GuardDuty analyzes EKS audit logs for:

- Privilege escalation attempts
- Sensitive volume mounts
- Runc profiles violations
- Anonymous access
- Compromised credentials
- Exposed credentials

This requires CloudTrail logging to be enabled on the account. Ensure
`cloudtrail` data source is configured.

## S3 Protection

When `enable_s3_logs = true`, GuardDuty monitors:

- GetObject, ListObject, PutObject API calls
- Bucket policy changes
- Access point operations

S3 Protection requires GuardDuty to be enabled at the AWS Organization level
or individual account level with S3 buckets scanned.

## Malware Protection

When `enable_malware_protection = true`, GuardDuty scans EBS volumes attached
to EC2 instances when:

- A new volume is attached
- A snapshot is created
- On-demand scanning is triggered

Scanned files matching known malware signatures generate GuardDuty findings.
Scanned volumes must have encryption enabled (KMS or SSE-S3).

## Findings Export

Export findings to S3 for:

- Long-term retention and compliance
- SIEM integration via Kinesis
- Automated response via EventBridge

Bucket should have:
- Lifecycle policy to archive old findings
- Bucket policy restricting access
- KMS encryption for sensitive finding data

## Security Notes

- GuardDuty findings are time-limited (90 days). Export for longer retention.
- Enable GuardDuty at the AWS Organization level for centralized monitoring.
- GuardDuty uses machine learning to detect threats — no rules to maintain.
- Cross-region findings aggregation requires separate detectors per region.
