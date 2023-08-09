# AWS Security Hardening Guide

## Overview

This guide describes the security controls available across the AWS modules and the recommended settings for production deployments.

---

## EKS

### IMDSv2 Enforcement

All node groups use a launch template that enforces IMDSv2 (token-based metadata) and restricts the hop limit to 1. This prevents pods from accessing the EC2 instance metadata service (IMDS) and leaking node IAM credentials.

```hcl
module "eks" {
  # ...
  imdsv2_required                       = true   # default
  metadata_http_put_response_hop_limit  = 1       # default
}
```

### API Server Access

Restrict public access to the API server with an IP allowlist:

```hcl
module "eks" {
  # ...
  endpoint_public_access = true
  public_access_cidrs    = ["203.0.113.0/24"]  # your office/VPN CIDR
}
```

For maximum security in production, disable the public endpoint entirely and use a VPN or AWS Direct Connect to reach the private endpoint:

```hcl
module "eks" {
  # ...
  endpoint_public_access = false
}
```

### Secrets Encryption

Encrypt Kubernetes secrets at rest with a dedicated KMS key:

```hcl
module "kms" {
  source      = "../../modules/aws/kms"
  project     = var.project
  environment = var.environment
  enable_general_key = true
}

module "eks" {
  # ...
  kms_key_arn = module.kms.general_key_arn
}
```

---

## VPC

### Flow Logs

Enable VPC flow logs to capture all traffic for forensics and anomaly detection:

```hcl
module "vpc" {
  # ...
  enable_flow_logs                         = true
  flow_logs_destination                    = "cloud-watch-logs"
  flow_logs_cloudwatch_log_group_name      = "/aws/vpc/flow-logs"
  flow_logs_traffic_type                   = "ALL"
}
```

---

## S3 State Bucket

### Access Logging

Enable access logging on the state bucket to audit who accessed the state:

```hcl
module "s3_state" {
  # ...
  access_log_bucket = aws_s3_bucket.logs.id
  access_log_prefix = "tfstate-access/"
}
```

---

## IAM

### Permissions Boundary

Apply a permissions boundary to the CI apply role to prevent privilege escalation:

```hcl
module "iam" {
  # ...
  permissions_boundary_arn = "arn:aws:iam::${var.account_id}:policy/AllowedBoundary"
}
```

### OIDC + Branch Protection

The apply role enforces `StringEquals` on the branch ref, ensuring only merges to `main` can assume the high-privilege apply role. The plan role uses `StringLike` to allow all branches to plan.

---

## Compliance Baseline

| Control | Module | Default | Recommended |
|---------|--------|---------|-------------|
| Secrets encryption | `eks` | Off | On (KMS key) |
| IMDSv2 | `eks` | On | On |
| Public endpoint restriction | `eks` | Open | CIDR allowlist |
| VPC flow logs | `vpc` | Off | On |
| S3 access logging | `s3-state` | Off | On |
| KMS key rotation | `kms` | On | On |
| Permissions boundary | `iam` | Off | On in prod |
