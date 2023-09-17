# ADR-001: Remote State Backend Strategy

**Date:** 2023-11-01
**Status:** Accepted

## Context

Terraform state must be stored remotely to support team collaboration,
state locking, and CI/CD pipelines. We needed to choose a backend for
each cloud and decide whether to use a unified cross-cloud backend or
cloud-native backends per deployment.

Options considered:
1. S3 + DynamoDB for AWS, Azure Blob for Azure (cloud-native per cloud)
2. Terraform Cloud as a unified backend
3. Self-hosted MinIO or Consul

## Decision

Use **cloud-native backends per cloud**:
- AWS deployments → S3 bucket + DynamoDB lock table (via `modules/aws/s3-state` + `modules/aws/dynamodb-lock`)
- Azure deployments → Azure Blob Storage with lease-based locking

Bootstrap via `bootstrap/` directory before any module is applied.

## Consequences

**Positive:**
- No external SaaS dependency
- State encryption at rest using cloud-native KMS
- State locking prevents concurrent modifications
- Audit trail via S3 versioning / Azure blob versioning

**Negative:**
- Two separate backend configurations to maintain
- Cross-cloud state references require `terraform_remote_state` data sources
- Bootstrap must be applied manually before pipelines can run

## References

- [AWS Backend Guide](../aws-backend.md)
- [Azure Backend Guide](../azure-backend.md)
- `bootstrap/` directory for one-time setup
