# -----------------------------------------------------------------------------
# Node Group Launch Template
# -----------------------------------------------------------------------------
# Enforces IMDSv2 and restricts metadata endpoint hop limit to 1 so that
# pods cannot reach the instance metadata service directly.
# Sets the root EBS volume size from node_groups[*].disk_size (default 50 GB).
# Supports custom AMI IDs for Bottlerocket and hardened AL2 builds.
# -----------------------------------------------------------------------------

resource "aws_launch_template" "node" {
  for_each = var.node_groups

  name_prefix = "${local.cluster_name}-${each.key}-"

  # When custom_ami_id is set on the node group, use it as the launch template
  # image_id. The node group must also set ami_type = "CUSTOM" so EKS does not
  # override this value. Set to null for standard AL2/Bottlerocket AMI types.
  image_id = each.value.custom_ami_id

  # Configure the root EBS volume with the size specified in the node group
  # definition. Without this block the managed node group defaults to 20 GB,
  # silently ignoring the disk_size field. gp3 gives better baseline IOPS than
  # gp2 at the same cost, and encrypted=true satisfies CIS Benchmark 5.1.1.
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = each.value.disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.imdsv2_required ? "required" : "optional"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name      = "${local.cluster_name}-${each.key}"
      NodeGroup = each.key
    })
  }

  # Tag EBS root volumes so they appear in cost allocation reports and
  # are correctly attributed to the node group that owns them.
  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name      = "${local.cluster_name}-${each.key}-root"
      NodeGroup = each.key
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}
