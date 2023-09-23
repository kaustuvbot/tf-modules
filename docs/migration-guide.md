# Migration Guide

This guide covers breaking changes and migration steps when upgrading between
versions of this Terraform module repository.

---

## Migrating to v1.0.0 (upcoming)

### Overview

v1.0.0 will be the first stable release. It completes the Phase 5 cleanup arc:
variable renames are finalized, deprecated variables will be removed, and
the AKS node pool output key changes from `user_node_pool_ids` to
`node_pool_ids` for consistency.

**Recommended:** migrate deprecated inputs before the v1.0.0 cut to avoid
forced changes on the release upgrade.

---

### AWS EKS Module

#### `cluster_version` → `kubernetes_version`

**Deprecated since:** v0.9.0

```hcl
# Before (v0.x)
module "eks" {
  source          = "..."
  cluster_version = "1.28"
}

# After (v1.0.0)
module "eks" {
  source             = "..."
  kubernetes_version = "1.28"
}
```

**Migration:** Rename the variable. No infrastructure change — `coalesce()` in
the module means both names produce the same `version` attribute on the cluster.

---

#### `vpc_cni_version` / `coredns_version` / `kube_proxy_version` → `managed_addon_versions`

**Deprecated since:** v0.9.0

```hcl
# Before (v0.x)
module "eks" {
  source             = "..."
  vpc_cni_version    = "v1.16.0-eksbuild.1"
  coredns_version    = null
  kube_proxy_version = null
}

# After (v1.0.0)
module "eks" {
  source = "..."
  managed_addon_versions = {
    "vpc-cni" = "v1.16.0-eksbuild.1"
    # omit coredns and kube-proxy to use latest
  }
}
```

**Migration:** Move versions into the `managed_addon_versions` map. Omitting a
key is equivalent to setting the old variable to `null` (uses latest).

---

### Azure AKS Module

#### `node_pool_ids` output rename (breaking in v1.0.0)

The output `user_node_pool_ids` will be renamed to `node_pool_ids` in v1.0.0
for consistency with the internal resource key naming.

```hcl
# Before (v0.x)
output "my_pool" {
  value = module.aks.user_node_pool_ids["apps"]
}

# After (v1.0.0)
output "my_pool" {
  value = module.aks.node_pool_ids["apps"]
}
```

**Note:** Until v1.0.0, `user_node_pool_ids` remains the correct output name.

---

## Migrating to v0.9.0

### EKS: IMDSv2 now enforced by default

`imdsv2_required` defaults to `true` and `metadata_http_put_response_hop_limit`
defaults to `1` as of v0.9.0. Existing EKS node groups will see a launch
template update on next `terraform apply`.

**Impact:** Rolling node group replacement. Plan the apply in a maintenance
window and ensure the cluster autoscaler can reprovision nodes.

To opt out temporarily:
```hcl
module "eks" {
  imdsv2_required                       = false
  metadata_http_put_response_hop_limit  = 2
}
```

### EKS: CloudWatch log group now created explicitly

An `aws_cloudwatch_log_group` for `/aws/eks/<cluster>/cluster` is now created
by the EKS module with 90-day retention. If you previously created this log
group externally, import it before applying:

```bash
terraform import module.eks.aws_cloudwatch_log_group.eks_cluster /aws/eks/<cluster-name>/cluster
```

### VPC: Route table association changed from `count` to `for_each`

`aws_route_table_association.private` changed from `count` to `for_each` in
v0.9.0. Terraform will destroy and recreate these associations on the first
apply. This is a non-destructive change (route table associations are
stateless), but will appear as `destroy + create` in the plan.

---

## Version History

| Version | Phase | Key Change |
|---------|-------|------------|
| v0.9.0 | Phase 4 complete | Security hardening, IMDSv2, PSA, Defender, VPC endpoints |
| v0.8.x | Phase 3/4 | Advanced config, dynamic blocks, environments |
| v0.7.x | Phase 2/3 | Optional configs, tagging, validation |
| v0.1–v0.6 | Phase 1/2 | Initial modules, core functionality |
