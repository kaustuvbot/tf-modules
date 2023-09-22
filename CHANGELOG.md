# Changelog

All notable changes to this repository are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses semantic versioning starting from v0.9.0.

---

## [Unreleased]

### Added
- `kubernetes_version` variable in EKS module (supersedes deprecated `cluster_version`)
- `managed_addon_versions` map variable in EKS module (supersedes deprecated individual addon version variables)
- `enable_cluster_autoscaler_irsa` variable in EKS module for Karpenter/CA IRSA role

### Changed
- `cluster_version` marked as deprecated; use `kubernetes_version`
- `vpc_cni_version`, `coredns_version`, `kube_proxy_version` marked as deprecated; use `managed_addon_versions`

---

## [0.9.0] — Phase 4 Security Hardening Complete

### Security

#### AWS EKS
- IMDSv2 enforced by default (`imdsv2_required = true`, `metadata_http_put_response_hop_limit = 1`)
- Pod Security Admission namespace mapping via `pod_security_standards` variable; `psa_namespace_labels` output
- Cluster API authentication mode configurable via `authentication_mode` variable (`access_config` block)
- KMS secrets encryption in prod via `kms_key_arn` validation
- CloudWatch log group retention controlled via `cluster_log_retention_days` (default 90 days)
- EKS managed add-ons version consolidation via `managed_addon_versions` map

#### AWS EKS Add-ons
- WAFv2 + Shield Advanced integration via `enable_waf_v2` on ALB controller
- Default TLS 1.3 SSL policy via `alb_default_ssl_policy`
- Shared Helm release defaults extracted to `locals.tf` (atomic, cleanup_on_fail, wait)

#### AWS VPC
- S3 Gateway VPC Endpoint via `enable_s3_vpc_endpoint`
- ECR Interface VPC Endpoints via `enable_ecr_vpc_endpoints` (ecr.api + ecr.dkr)

#### AWS KMS
- `bypass_policy_lockout_safety_check` variable (default false) on all key resources

#### Azure AKS
- Microsoft Defender for Containers via `enable_defender` + `log_analytics_workspace_id`
- Automatic upgrade channel via `auto_upgrade_channel` (default "patch")
- Private cluster enforced in prod environments

#### Azure VNet
- Deny-all egress NSG rule per subnet
- DDoS Protection Standard plan attachment
- NSG flow log integration

### Added

#### Modules
- `enable_s3_vpc_endpoint` — AWS VPC Gateway Endpoint for S3
- `enable_ecr_vpc_endpoints` — AWS VPC Interface Endpoints for ECR
- `cluster_log_retention_days` — EKS CloudWatch log group retention
- `pod_security_standards` / `authentication_mode` — EKS security controls
- `enable_defender` / `log_analytics_workspace_id` — AKS Defender
- `auto_upgrade_channel` — AKS automatic patch upgrades
- `bypass_policy_lockout_safety_check` — KMS key safety

#### Tests
- Terratest for AWS budgets module (`tests/aws/budgets_test.go`)
- Terratest for AWS logging module (`tests/aws/logging_test.go`)
- Terratest for Azure key-vault module (`tests/azure/keyvault_test.go`)
- Extended AKS Terratest: kubelet identity + node pool outputs
- Extended VPC Terratest: route table count + subnet regression

#### Documentation
- AKS module README (`modules/azure/aks/README.md`)
- Azure VNet module README (`modules/azure/vnet/README.md`)
- Azure key-vault module README (`modules/azure/key-vault/README.md`)
- core/naming module README (`modules/core/naming/README.md`)
- core/tagging module README (`modules/core/tagging/README.md`)
- Root README Phase 4 security hardening section expanded

#### CI/CD
- Expanded GitHub Actions validate matrix from 6 to 16 modules

### Refactored
- EKS managed-addons: `managed_addon_versions` map with backward-compat merge
- VPC route table association: extracted to `private_subnet_route_table_index` local
- eks-addons Helm release defaults centralized in `locals.tf`

---

## Prior to v0.9.0

Changes prior to v0.9.0 were tracked in commit messages only.
See `git log --oneline` for the full history of Phases 1–3.

[Unreleased]: https://github.com/your-org/tf-modules/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/your-org/tf-modules/releases/tag/v0.9.0
