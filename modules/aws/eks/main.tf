# -----------------------------------------------------------------------------
# AWS EKS Module
# -----------------------------------------------------------------------------
# Manages an EKS cluster with managed node groups.
#
# Resources created:
#   - EKS cluster (this file)
#   - Managed node groups (this file)
#   - OIDC provider for IRSA (this file)
#   - IAM roles and policy attachments (iam.tf)
#   - Node group launch template (launch-template.tf)
#   - Managed add-ons (managed-addons.tf)
# -----------------------------------------------------------------------------

# Warn when both kubernetes_version and the deprecated cluster_version are set.
# coalesce() will silently favour kubernetes_version, so the cluster_version
# value is ignored. Surfacing this at plan time avoids silent misconfiguration.
check "kubernetes_version_mutual_exclusion" {
  assert {
    condition     = !(var.cluster_version != null && var.kubernetes_version != "1.28")
    error_message = "Both kubernetes_version and the deprecated cluster_version are set. Remove cluster_version — kubernetes_version takes precedence and cluster_version is ignored."
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------
# Create the log group explicitly so we can control retention. Without this,
# EKS creates it automatically with no expiry (retention = never).
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = merge(local.common_tags, {
    Name = "/aws/eks/${local.cluster_name}/cluster"
  })
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = coalesce(var.kubernetes_version, var.cluster_version)
  role_arn = aws_iam_role.cluster.arn

  enabled_cluster_log_types = var.enabled_cluster_log_types

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = length(var.public_access_cidrs) > 0 ? var.public_access_cidrs : null
  }

  dynamic "encryption_config" {
    for_each = var.kms_key_arn != null ? [1] : []

    content {
      provider {
        key_arn = var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  tags = merge(local.common_tags, {
    Name = local.cluster_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_controller,
    aws_cloudwatch_log_group.eks_cluster,
  ]
}

# -----------------------------------------------------------------------------
# Managed Node Groups
# -----------------------------------------------------------------------------

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  ami_type       = each.value.ami_type
  labels         = each.value.labels

  launch_template {
    id      = aws_launch_template.node[each.key].id
    version = aws_launch_template.node[each.key].latest_version
  }

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  update_config {
    max_unavailable = 1
  }

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.cluster_name}-${each.key}"
    NodeGroup = each.key
  })

  # Ignore desired_size changes after initial creation so the cluster
  # autoscaler can freely scale node counts without Terraform reverting them.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}

# -----------------------------------------------------------------------------
# OIDC Provider for IRSA (IAM Roles for Service Accounts)
# -----------------------------------------------------------------------------
# data.tls_certificate.eks is defined in data.tf.

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-oidc"
  })
}

