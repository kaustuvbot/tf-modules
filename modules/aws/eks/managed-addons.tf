# -----------------------------------------------------------------------------
# EKS Managed Add-ons
# -----------------------------------------------------------------------------
# Manages the core EKS managed add-ons (vpc-cni, coredns, kube-proxy).
# These replace self-managed versions and receive security patches via
# AWS-managed updates.
# -----------------------------------------------------------------------------

locals {
  # Base versions from the deprecated individual variables. These are overridden
  # by any key present in managed_addon_versions, enabling a migration path.
  _addon_base_versions = {
    vpc-cni    = var.vpc_cni_version
    coredns    = var.coredns_version
    kube-proxy = var.kube_proxy_version
  }

  managed_addons = var.enable_managed_addons ? merge(
    local._addon_base_versions,
    var.managed_addon_versions,
  ) : {}
}

resource "aws_eks_addon" "this" {
  for_each = local.managed_addons

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-${each.key}"
  })

  depends_on = [aws_eks_node_group.this]
}
