# Senior DevOps Interview Q&A

Answers to common senior-level DevOps/Platform Engineering interview questions,
grounded in the architecture decisions made in this platform.

---

## Infrastructure as Code

**Q: How do you structure Terraform for a multi-cloud platform?**

A: One module per cloud service, organized under `modules/aws/`, `modules/azure/`,
`modules/gcp/`. A composition layer (`modules/multi/platform-blueprint`) wires
cloud-specific modules into a coherent stack behind a uniform interface.
State is stored in cloud-native backends (S3/DynamoDB for AWS, Blob for Azure)
with separate state files per environment.

**Q: How do you handle Terraform state in a team environment?**

A: Remote state with locking. AWS uses S3 + DynamoDB; Azure uses Blob Storage
with lease-based locks. The `bootstrap/` directory provisions these resources
before any other Terraform runs. Environments are isolated via separate state
files and separate backends, preventing cross-environment blast radius.

**Q: How do you prevent accidental infrastructure drift?**

A: Drift detection via scheduled GitHub Actions workflow that runs `terraform plan`
nightly and alerts on unexpected diffs. Module lifecycle blocks with
`ignore_changes` are used only for fields that drift by design
(e.g., AMI IDs managed by launch templates, auto-upgrade fields on AKS).

---

## Kubernetes (EKS / AKS)

**Q: How do you approach EKS node group strategy?**

A: System-critical workloads (CoreDNS, kube-proxy, controllers) run on
ON_DEMAND nodes in a dedicated system node group with a taint. Application
workloads use SPOT instances managed by Karpenter with fallback instance type
lists. Node Termination Handler ensures graceful draining before SPOT reclamation.

**Q: How do you manage Kubernetes add-ons at scale?**

A: Add-ons are managed via the `modules/aws/eks-addons` module using the Helm
provider. Versions are pinned in variables with explicit upgrade paths documented.
Install ordering is enforced with `depends_on` to prevent race conditions
(ALB controller before ExternalDNS, cert-manager before Ingress objects).

**Q: What is IRSA and why does it matter?**

A: IAM Roles for Service Accounts allows Kubernetes service accounts to assume
AWS IAM roles via the EKS OIDC provider — no static credentials on nodes.
Each add-on (ALB controller, ExternalDNS, Karpenter) gets its own least-privilege
IAM role with a trust policy scoped to its service account namespace + name.

---

## Security

**Q: How do you enforce least privilege in AWS IAM?**

A: CI/CD roles are split into plan-only (read) and apply (write) roles scoped
per environment. Condition keys (`aws:SourceAccount`, `sts:ExternalId`) are used
in trust policies. IRSA replaces node instance profiles for workload permissions.
GuardDuty + Security Hub provide continuous threat detection.

**Q: How do you handle secrets in Terraform?**

A: Secrets never live in `.tfvars` or state as plaintext. Patterns:
- Passwords generated with `random_password`, stored in SSM Parameter Store or
  Azure Key Vault, referenced by ARN/ID — never by value in outputs.
- CI/CD uses OIDC-based short-lived credentials (no stored access keys).
- `sensitive = true` on all outputs that might contain credentials.

---

## Networking

**Q: How do you design VPC/VNet for EKS/AKS?**

A: Private subnets for nodes (no direct internet exposure), NAT gateway per AZ
for egress. VPC endpoints for ECR, S3, SSM reduce NAT costs and prevent internet
routing for cluster traffic. Node security groups allow only necessary ingress
from the control plane.

**Q: How do you approach multi-region disaster recovery?**

A: DR is documented in `docs/dr-patterns.md`. Active-passive via Route53 health
checks and failover routing. Each region is an independent Terraform workspace
with its own state. Recovery automation is out of scope for this platform but
the module hooks (Route53, WAF) are designed to support it.

---

## CI/CD

**Q: How do you structure Terraform CI/CD pipelines?**

A: GitHub Actions with separate jobs for `fmt`, `validate`, `tfsec/checkov`,
`plan` (on PR), and `apply` (on merge to main). Environment promotions use
GitHub Environment protection rules with required reviewers. A nightly scheduled
workflow runs `terraform plan` across all modules to detect drift.

**Q: How do you manage provider version upgrades safely?**

A: Providers are pinned with `~>` constraints (allow patch, block major).
Upgrade PRs bump the constraint and pin in `.terraform.lock.hcl`. The upgrade
is tested against all Terratest suites before merging. Renovate/Dependabot
can be configured to open upgrade PRs automatically.
