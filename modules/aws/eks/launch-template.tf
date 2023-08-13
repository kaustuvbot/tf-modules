# -----------------------------------------------------------------------------
# Node Group Launch Template
# -----------------------------------------------------------------------------
# Enforces IMDSv2 and restricts metadata endpoint hop limit to 1 so that
# pods cannot reach the instance metadata service directly.
# -----------------------------------------------------------------------------

resource "aws_launch_template" "node" {
  for_each = var.node_groups

  name_prefix = "${local.cluster_name}-${each.key}-"

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

  lifecycle {
    create_before_destroy = true
  }
}
