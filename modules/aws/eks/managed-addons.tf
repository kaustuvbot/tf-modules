# -----------------------------------------------------------------------------
# EKS Managed Add-ons
# -----------------------------------------------------------------------------
# Manages the core EKS managed add-ons (vpc-cni, coredns, kube-proxy).
# These replace self-managed versions and receive security patches via
# AWS-managed updates.
# -----------------------------------------------------------------------------

variable "enable_managed_addons" {
  description = "Enable EKS managed add-ons (vpc-cni, coredns, kube-proxy)"
  type        = bool
  default     = true
}

variable "vpc_cni_version" {
  description = "Version of the vpc-cni managed add-on. null = latest."
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "Version of the coredns managed add-on. null = latest."
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "Version of the kube-proxy managed add-on. null = latest."
  type        = string
  default     = null
}

locals {
  managed_addons = var.enable_managed_addons ? {
    vpc-cni    = var.vpc_cni_version
    coredns    = var.coredns_version
    kube-proxy = var.kube_proxy_version
  } : {}
}

resource "aws_eks_addon" "this" {
  for_each = local.managed_addons

  cluster_name             = aws_eks_cluster.this.name
  addon_name               = each.key
  addon_version            = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-${each.key}"
  })

  depends_on = [aws_eks_node_group.this]
}
