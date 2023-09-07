# Changelog

All notable changes to this repository are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses semantic versioning starting from v0.9.0.

---

## [Unreleased]

---

## [1.0.0] — Phase 5–6: Module Completeness + v1.0.0

### Added

#### AWS EKS
- `disk_size` field now wired into launch template `block_device_mappings` (gp3, encrypted)
- `custom_ami_id` field in node_groups for Bottlerocket and hardened AL2 custom AMIs
- `kubernetes_version` variable (supersedes deprecated `cluster_version`); format validated (`MAJOR.MINOR`)
- `managed_addon_versions` map variable (supersedes deprecated `vpc_cni_version`, `coredns_version`, `kube_proxy_version`)
- `enable_cluster_autoscaler_irsa` variable with OIDC IRSA role and policy; `cluster_autoscaler_role_arn` output
- `check` block warning when both `kubernetes_version` and deprecated `cluster_version` are set simultaneously
- SPOT node_groups validation: at least 2 `instance_types` required (capacity pool diversification)
- IAM roles extracted into `iam.tf` for improved module navigability

#### AWS eks-addons
- `enable_node_termination_handler` — AWS NTH in IMDS mode for SPOT graceful draining
- `enable_sealed_secrets` — Bitnami Sealed Secrets controller for GitOps secret management
- `enable_karpenter` — Karpenter with IRSA role, SQS interruption queue, and EventBridge rules
- `enable_efs_csi_driver` — EFS CSI Driver as EKS managed add-on for ReadWriteMany volumes
- Input validations: `oidc_provider_url` requires `https://` prefix; `route53_zone_ids` validates AWS zone ID format
- Outputs: `karpenter_role_arn`, `karpenter_sqs_queue_url`, `efs_csi_addon_id`
- `examples/aws-eks-with-addons/` end-to-end example demonstrating OIDC output wiring

#### Azure AKS
- `system_node_pool_os_disk_size_gb` and `system_node_pool_os_disk_type` (Managed/Ephemeral) for system node pool
- Outputs: `node_resource_group`, `fqdn`, `private_fqdn` (mutually exclusive based on cluster visibility)

#### New Modules
- `modules/aws/ecr` — ECR repositories with scan-on-push, lifecycle policies, and optional KMS encryption
- `modules/azure/container-registry` — ACR with SKU selection, geo-replication, zone redundancy
- `modules/azure/private-dns` — Private DNS zones and VNet links for AKS private cluster resolution

### Changed
- `cluster_version` deprecated; use `kubernetes_version`
- `vpc_cni_version`, `coredns_version`, `kube_proxy_version` deprecated; use `managed_addon_versions`
- All Azure provider version constraints normalized to `~> 3.0`
- Helm provider normalized to `~> 2.0`, Kubernetes provider to `~> 2.0`

### Tests Added
- `tests/aws/ecr_test.go` — ECR repository URL and ARN validation
- `tests/azure/container_registry_test.go` — ACR login_server validation
- `tests/azure/private_dns_test.go` — Private DNS zone name and VNet link validation
- Extended `tests/aws/eks_test.go` — validates `cluster_autoscaler_role_arn` and `disk_size`

### Documentation
- `docs/eks-node-groups.md` — Instance selection, SPOT, disk sizing, taints, Karpenter interaction
- `docs/karpenter-migration.md` — Cluster Autoscaler to Karpenter migration guide
- `modules/aws/ecr/README.md` — ECR lifecycle, IMMUTABLE tags, cross-account pull
- `modules/azure/container-registry/README.md` — SKU comparison, RBAC, geo-replication, private endpoint
- `modules/azure/private-dns/README.md` — AKS private cluster DNS zones, hub-and-spoke pattern
- CI: `terraform-validate.yml` matrix expanded to 18 modules

---

## [0.9.0] — Phase 4 Security Hardening Complete

### Security

#### AWS EKS
- IMDSv2 enforced by default (`imdsv2_required = true`, `metadata_http_put_response_hop_limit = 1`)
- Pod Security Admission namespace mapping via `pod_security_standards` variable; `psa_namespace_labels` output
- Cluster API authentication mode configurable via `authentication_mode` variable (`access_config` block)

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
