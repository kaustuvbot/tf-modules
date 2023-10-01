# AWS Security Modules Operational Guide

Guide for operating GuardDuty and Security Hub modules in production environments.

## GuardDuty

### Initial Setup

GuardDuty requires no initial configuration — enable the detector and configure data sources:

```hcl
module "guardduty" {
  source = "./modules/aws/guardduty"

  project     = "myapp"
  environment = "prod"

  enable_kubernetes_logs    = true
  enable_s3_logs           = false  # Enable if S3 contains sensitive data
  enable_malware_protection = false  # Additional cost
}
```

### Data Sources by Environment

| Environment | S3 Logs | Kubernetes | Malware | Cost Impact |
|-------------|---------|------------|---------|-------------|
| dev | false | false | false | ~$3/month |
| staging | false | true | false | ~$6/month |
| prod | true | true | true | ~$15/month |

### Organization-Level Enable

For multi-account environments, enable GuardDuty at the organization level:

```hcl
# In security account or Org management account
resource "aws_guardduty_organization_admin_account" "admin" {
  admin_account_id = var.security_account_id
}
```

Then each member account can optionally configure their own data sources.

### Findings Response

GuardDuty findings trigger via EventBridge:

```hcl
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name = "guardduty-findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn
}
```

### Common Findings

| Finding Type | Severity | Action |
|--------------|----------|--------|
| Recon:EC2/Portscan | Medium | Review instance security groups |
| Exfiltration:S3/MaliciousIP | High | Investigate bucket access logs |
| CredentialAccess:IAMUser/MaliciousIP | Critical | Rotate credentials immediately |
| Persistence:IAMUser/RootCredentialUsage | Critical | Investigate and disable root access |

## Security Hub

### Standards Overview

| Standard | Controls | Compliance Framework | Enable by Default |
|----------|----------|---------------------|-------------------|
| CIS AWS Foundations | ~43 | AWS Best Practices | Yes |
| AWS Foundational Security | ~200 | AWS Best Practices | Yes |
| PCI DSS | ~44 | PCI-DSS 3.2.1 | No (requires audit) |

### Enable Standards

```hcl
module "security_hub" {
  source = "./modules/aws/security-hub"

  project     = "myapp"
  environment = "prod"

  enable_cis_standard              = true
  enable_aws_foundational_standard = true
  enable_pci_dss_standard         = false  # Enable for PCI environments

  auto_enable_controls = true  # Automatically enable new controls
}
```

### Organization-Level Aggregation

For centralized security visibility:

```hcl
# In security account
resource "aws_securityhub_organization_admin_account" "admin" {
  admin_account_id = var.security_account_id
}

resource "aws_securityhub_finding_aggregator" "allRegions" {
  # Aggregate findings from all regions
  region_linking_mode = "ALL_REGIONS"
}
```

Member accounts automatically send findings to the aggregator.

### Findings Integration

```hcl
# Send Security Hub findings to SNS
resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  name = "securityhub-findings"

  event_pattern = jsonencode({
    source        = ["aws.securityhub"]
    "detail-type" = ["Security Hub Findings - Imported"]
  })
}

resource "aws_cloudwatch_event_target" "securityhub_sns" {
  rule = aws_cloudwatch_event_rule.securityhub_findings.name
  arn  = aws_sns_topic.security_alerts.arn
}
```

### Severity Response

| Severity | Response Time | Example |
|----------|---------------|---------|
| CRITICAL | 1 hour | Exposed credentials, active compromise |
| HIGH | 24 hours | Missing encryption, overly permissive IAM |
| MEDIUM | 7 days | Weak password policy, missing MFA |
| LOW | 30 days | Informational, best practice gaps |

### Compliance Dashboards

Security Hub integrates with:

- **AWS Console**: Security Hub dashboard shows compliance score
- **Amazon Detective**: Investigate findings graphically
- **AWS Security Hub API**: Export to SIEM via findings export
- **Jira/ServiceNow**: Create tickets from findings via EventBridge

## Cost Optimization

### GuardDuty Costs

| Data Source | Cost per Account |
|-------------|-----------------|
| CloudTrail events | Included |
| VPC Flow Logs | Included |
| DNS Logs | Included |
| EKS Audit Logs | ~$3/month |
| S3 Data Events | ~$5/month |
| Malware Protection | ~$5/month |

### Security Hub Costs

| Standard | Cost per Account |
|----------|-----------------|
| CIS | Free |
| AWS Foundational | Free |
| PCI DSS | Free |

Security Hub is free for all standards — only GuardDuty and third-party integrations cost.

## Troubleshooting

### GuardDuty Not Receiving Events

1. Verify CloudTrail is enabled in the account
2. Check GuardDuty detector status is `ENABLED`
3. For EKS: ensure CloudTrail is logging data events

### Security Hub Controls Failing

1. Check control requirements in AWS Console
2. Some controls require additional services (Config, CloudTrail)
3. Run `aws securityhub describe-standards-controls` for details

## Module Updates

Both modules follow semantic versioning. Update via:

```bash
terraform get -update
```

Check changelog for breaking changes before upgrading.
