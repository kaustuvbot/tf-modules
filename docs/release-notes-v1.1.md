# Release Notes v1.1

Version 1.1 adds GCP support, security hardening, and lifecycle management.

## Highlights

- **GCP Module Support**: First-class GCP modules for VPC, GKE, IAM, Cloud KMS, and Storage
- **Multi-Cloud Blueprint**: Tri-cloud composition support in `multi/platform-blueprint`
- **Security Hardening**: WAF improvements, S3 Object Lock, TLS-only policies
- **Lifecycle Management**: ECR replication, KMS multi-region keys, S3 intelligent-tiering
- **Test Coverage**: Terratest scaffolding for GCP modules

## New Modules

### GCP Modules

| Module | Description |
|--------|-------------|
| `gcp/vpc-network` | VPC with subnets, Cloud NAT, private service access |
| `gcp/gke` | GKE cluster with node pools, workload identity, shielded nodes |
| `gcp/iam` | Service accounts with workload identity bindings |
| `gcp/cloudkms` | KMS key ring and crypto keys with rotation |
| `gcp/storage` | GCS buckets with versioning, lifecycle rules, IAM |

## Features Added

### AWS

- `aws/s3-state`: Object Lock for WORM compliance
- `aws/s3-state`: Intelligent-Tiering for cost optimization
- `aws/s3-state`: TLS-only bucket policy (deny non-TLS)
- `aws/ecr`: Cross-region replication configuration
- `aws/kms`: Multi-region replica key support

### Azure

- `azure/front-door`: Complete module with routing rules, WAF integration, health probes

### GCP (New)

- All new modules support labels, versioning, and IAM bindings

### Core

- `core/tagging`: GCP label support (lowercase keys)
- `core/naming`: GCP naming conventions (lowercase)

### Multi-Cloud

- `multi/platform-blueprint`: GCP stack wiring

## Documentation

- `docs/gcp-getting-started.md`: GCP onboarding guide
- `docs/aws-security-modules.md`: GuardDuty and Security Hub operations
- `docs/aws-upgrade-guide.md`: EKS and module upgrade procedures
- `docs/gcp-security.md`: GKE hardening and workload identity
- `docs/multi-cloud-architecture.md`: AWS/Azure/GCP comparison

## Examples

- `examples/gcp-vpc-gke`: Basic GCP networking and GKE
- `examples/gcp-complete`: Full GCP stack with VPC, GKE, KMS, Storage, IAM
- `examples/multi-cloud-ha`: Tri-cloud failover with Route53

## Breaking Changes

None. This release is backward-compatible with v1.0.x.

## Migration from v1.0

No migration required. Existing configurations continue to work.

## Upgrade Path

```bash
# Update module source to v1.1
source = "git::https://github.com/yourorg/tf-modules.git//modules/aws/vpc?ref=v1.1"
```

## Known Issues

- GCP module tests are skeletal (require credentials)
- Multi-cloud HA example requires valid provider configurations

## Contributors

- Platform Team

## License

See LICENSE file for details.
