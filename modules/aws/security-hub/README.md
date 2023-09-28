# AWS Security Hub Module

Manages AWS Security Hub with CIS AWS Foundations Benchmark, AWS Foundational
Security Best Practices, and PCI DSS standards subscriptions.

## Usage

### Basic Security Hub with CIS and AWS Foundational Standards

```hcl
module "security_hub" {
  source = "../../modules/aws/security-hub"

  project     = "myapp"
  environment = "prod"

  enable_cis_standard              = true
  enable_aws_foundational_standard = true

  tags = {
    Team = "security"
  }
}
```

### Security Hub with PCI DSS for Compliance

```hcl
module "security_hub_compliance" {
  source = "../../modules/modules/aws/security-hub"

  project     = "myapp"
  environment = "prod"

  enable_cis_standard              = true
  enable_aws_foundational_standard = true
  enable_pci_dss_standard         = true

  auto_enable_controls = true

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
| `enable_cis_standard` | `bool` | `true` | Enable the CIS AWS Foundations Benchmark security standard |
| `enable_aws_foundational_standard` | `bool` | `true` | Enable the AWS Foundational Security Best Practices standard |
| `enable_pci_dss_standard` | `bool` | `false` | Enable the PCI DSS security standard |
| `auto_enable_controls` | `bool` | `true` | Automatically enable new controls as they are added |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `hub_arn` | ARN of the Security Hub account enablement |
| `enabled_standards` | List of enabled standard ARNs |

## Supported Standards

### CIS AWS Foundations Benchmark (v1.2.0)

Industry-recognized benchmark for securing AWS accounts. Covers:

- Identity and Access Management
- Logging
- Monitoring
- Networking
- Instance Tenancy
- S3

~43 checks depending on resource usage.

### AWS Foundational Security Best Practices (v1.0.0)

AWS-authored security standard covering:

- Compute
- Networking
- Storage
- Databases
- Security Identity & Compliance

~200 checks covering AWS service security configurations.

### PCI DSS v3.2.1

Payment Card Industry Data Security Standard compliance:

- Network security
- Data protection
- Vulnerability management
- Access control
- Monitoring and testing

Requires explicit enablement — disabled by default.

## Control Categories

Security Hub checks controls across categories:

| Category | Description |
|----------|-------------|
| Security | IAM, KMS, Lambda, EC2 security |
| Networking | VPC, Subnet, Security Group rules |
| Logging | CloudTrail, Config, GuardDuty |
| Data Protection | S3, RDS, DynamoDB encryption |
| Incident Response | Backup, CloudFormation |

## Findings

Security Hub aggregates findings from:

- AWS Config
- GuardDuty
- Inspector
- Macie
- Systems Manager Patch Manager

Findings are categorized by severity:

- **CRITICAL**: Active exploitation or data breach risk
- **HIGH**: Significant security misconfiguration
- **MEDIUM**: Moderate risk requiring attention
- **LOW**: Informational or minor issues

## Integration

### EventBridge (CloudWatch Events)

```hcl
resource "aws_cloudwatch_event_rule" "security_hub_findings" {
  name = "security-hub-findings"

  event_pattern = jsonencode({
    "source" : ["aws.securityhub"],
    "detail-type" : ["Security Hub Findings - Imported"]
  })
}
```

### Security Hub Aggregator

For multi-account environments, create a Security Hub aggregator to centralize
findings:

```hcl
resource "aws_securityhub_organization_admin_account" "admin" {
  admin_account_id = var.admin_account_id
}

resource "aws_securityhub_finding_aggregator" "aggregator" {
  # In aggregator account
}
```

## Security Notes

- Enable at AWS Organization level for centralized visibility.
- CIS standard is read-only — it reports but doesn't enforce.
- AWS Foundational standard may generate false positives — review controls.
- PCI DSS standard requires annual audit for compliance certification.
- Use `auto_enable_controls = true` to stay current with new AWS security checks.
