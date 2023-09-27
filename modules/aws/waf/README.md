# AWS WAF Module

Manages an AWS WAFv2 Web ACL with optional rate limiting, AWS Managed Rules
common rule sets, and ALB association.

## Usage

### Basic WAF with Rate Limiting

```hcl
module "waf" {
  source = "../../modules/aws/waf"

  project     = "myapp"
  environment = "prod"

  enable_rate_limiting = true
  rate_limit_threshold = 2000  # requests per 5-minute window per IP

  enable_aws_managed_common_ruleset = true
  enable_aws_managed_bad_inputs    = true

  tags = {
    Team = "platform"
  }
}
```

### WAF with ALB Association

```hcl
module "waf_alb" {
  source = "../../modules/aws/waf"

  project     = "myapp"
  environment = "prod"

  enable_rate_limiting          = true
  rate_limit_threshold         = 2000
  enable_aws_managed_common_ruleset = true
  enable_aws_managed_bad_inputs    = true
  enable_aws_managed_sql_injection = true

  alb_arn_list = [
    aws_lb.public.arn,
    aws_lb.internal.arn,
  ]

  tags = {
    Team = "platform"
  }
}
```

### CloudFront WAF (CLOUDFRONT scope)

```hcl
module "waf_cloudfront" {
  source = "../../modules/aws/waf"

  project     = "myapp"
  environment = "prod"
  scope       = "CLOUDFRONT"

  enable_rate_limiting            = true
  rate_limit_threshold           = 1000  # Lower for CloudFront
  enable_aws_managed_common_ruleset = true

  # No ALB association for CloudFront - attach to CloudFront distribution directly
  alb_arn_list = []

  tags = {
    Team = "platform"
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
| `scope` | `string` | `REGIONAL` | WAF scope: `REGIONAL` (ALB/API GW) or `CLOUDFRONT` (CloudFront) |
| `enable_rate_limiting` | `bool` | `true` | Enable rate-based rule to limit requests per IP |
| `rate_limit_threshold` | `number` | `2000` | Max requests per 5-minute window per IP before blocking |
| `enable_aws_managed_common_ruleset` | `bool` | `true` | Enable AWS Managed Rules Common Rule Set (OWASP Top 10) |
| `enable_aws_managed_bad_inputs` | `bool` | `true` | Enable AWS Managed Rules Known Bad Inputs Rule Set |
| `enable_aws_managed_sql_injection` | `bool` | `false` | Enable AWS Managed Rules SQL Database Rule Set |
| `alb_arn_list` | `list(string)` | `[]` | List of ALB ARNs to associate with this Web ACL |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `web_acl_id` | ID of the WAFv2 Web ACL |
| `web_acl_arn` | ARN of the WAFv2 Web ACL (use for CloudFront or manual ALB association) |
| `web_acl_name` | Name of the WAFv2 Web ACL |

## Rule Processing Order

Rules are evaluated in priority order:

| Priority | Rule | Description |
|----------|------|-------------|
| 1 | RateLimitPerIP | Rate-based blocking (when enabled) |
| 10 | AWSManagedRulesCommonRuleSet | OWASP Top 10 vulnerabilities |
| 20 | AWSManagedRulesKnownBadInputsRuleSet | Known bad input patterns |
| 30 | AWSManagedRulesSQLiRuleSet | SQL injection patterns |

## AWS Managed Rules

The module supports the following AWS Managed Rule Groups:

- **AWSManagedRulesCommonRuleSet**: Foundation rules covering OWASP Top 10
  risks including HTTP anomalies, IP reputation lists, and known bad inputs.

- **AWSManagedRulesKnownBadInputsRuleSet**: Rules that block requests with
  known malicious input patterns (e.g., shellshock, CVE patterns).

- **AWSManagedRulesSQLiRuleSet**: SQL injection protection rules. Enable for
  applications with database backends.

## Rate Limiting

The rate-based rule blocks IPs that exceed `rate_limit_threshold` requests
within a 5-minute window. Default threshold (2000) is suitable for normal
traffic. Adjust lower for:

- APIs with many clients: 500–1000
- Login endpoints: 50–100
- Background jobs: 10–20

## Security Notes

- Rate limiting uses client IP as the aggregate key. Behind a load balancer,
  ensure `X-Forwarded-For` is used (WAF handles this automatically).
- Managed rules use `override_action { none {} }` — they count matches but
  don't take action by default. Add custom rules to block specific matches.
- WAFv2 logging to CloudWatch Logs or Kinesis Data Firehose is recommended
  for security incident response.
