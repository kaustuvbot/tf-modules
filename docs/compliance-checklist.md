# Compliance Checklist

Use this checklist before promoting any environment to production.

## AWS

### Networking
- [ ] VPC has no default security group rules
- [ ] All subnets use private CIDRs for workload nodes
- [ ] NAT gateway enabled for egress (not open internet on nodes)
- [ ] VPC flow logs enabled and shipped to CloudWatch or S3
- [ ] VPC endpoints for S3, ECR, SSM (no NAT dependency for these)

### IAM
- [ ] No wildcard `*` actions in production IAM policies
- [ ] CI plan role is read-only; apply role is write-scoped per environment
- [ ] IRSA used for all EKS workload AWS access (no node instance profile secrets)
- [ ] MFA enforced on all human IAM users
- [ ] Access Analyzer enabled

### EKS
- [ ] Private API endpoint only (`cluster_endpoint_public_access = false`)
- [ ] Secrets encryption enabled (KMS)
- [ ] Control plane logs enabled (api, audit, authenticator, controllerManager, scheduler)
- [ ] IMDSv2 enforced on all node groups
- [ ] Pod Security Admission configured (at minimum `warn` mode)

### Security Services
- [ ] GuardDuty enabled with EKS audit log analysis
- [ with CIS + Foundational standards
- [ ] CloudTrail multi-region trail enabled ] Security Hub enabled
- [ ] Config recorder enabled

### Cost
- [ ] Monthly budget alert configured
- [ ] Cost Anomaly Detection enabled
- [ ] All resources tagged with Project + Environment + ManagedBy

---

## Azure

### Networking
- [ ] AKS nodes on private subnet
- [ ] NSG rules restrict inbound to known CIDRs only
- [ ] Private cluster enabled for production AKS
- [ ] Private DNS zone linked to VNet

### Identity
- [ ] Workload Identity enabled on AKS
- [ ] No service principal secrets in CI (use Federated Identity Credentials)
- [ ] RBAC only (no legacy Azure AD RBAC)
- [ ] Key Vault firewall restricts access to VNet or specific IPs

### AKS
- [ ] Private cluster API endpoint
- [ ] Azure Policy add-on enabled
- [ ] Defender for Containers enabled
- [ ] Node OS auto-upgrade configured

### Cost
- [ ] Budget alert configured per subscription
- [ ] All resources tagged with Project + Environment + ManagedBy

---

## Multi-Cloud

- [ ] All Terraform state in remote backend with locking
- [ ] State buckets have versioning + encryption enabled
- [ ] No plaintext secrets in `.tfvars` or committed state
- [ ] All modules pass `terraform validate`
- [ ] All modules pass `tfsec` / `checkov` with no HIGH findings
- [ ] Conftest mandatory-tag policy passes on `terraform plan` output
