# -----------------------------------------------------------------------------
# AWS Monitoring Module
# -----------------------------------------------------------------------------
# CloudWatch alarms and SNS notifications for infrastructure monitoring.
#
# Resources created:
#   - SNS topic for alarm notifications
#   - EKS cluster alarms (optional)
#   - Infrastructure alarms (CPU, memory)
# -----------------------------------------------------------------------------

locals {
  sns_topic_arn = var.sns_topic_arn != null ? var.sns_topic_arn : aws_sns_topic.alerts[0].arn

  # Shared alarm defaults — avoids repeating across every resource block
  alarm_actions    = [local.sns_topic_arn]
  ok_actions       = [local.sns_topic_arn]
  eks_dimensions   = { ClusterName = var.cluster_name }
  alarm_name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Module      = "monitoring"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# -----------------------------------------------------------------------------
# SNS Topic for Alarms
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  count = var.sns_topic_arn == null ? 1 : 0

  name = "${var.project}-${var.environment}-alerts"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alerts"
  })
}

# -----------------------------------------------------------------------------
# EKS Cluster Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "eks_cpu" {
  count = var.enable_eks_alarms ? 1 : 0

  alarm_name          = "${local.alarm_name_prefix}-eks-cpu-high"
  alarm_description   = "EKS cluster CPU utilization exceeds ${var.alarm_cpu_threshold}% for ${var.alarm_evaluation_periods} consecutive periods"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  datapoints_to_alarm = var.alarm_evaluation_periods
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = local.eks_dimensions

  alarm_actions = local.alarm_actions
  ok_actions    = local.ok_actions

  tags = merge(local.common_tags, {
    Alarm = "eks-cpu-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "eks_memory" {
  count = var.enable_eks_alarms ? 1 : 0

  alarm_name          = "${local.alarm_name_prefix}-eks-memory-high"
  alarm_description   = "EKS cluster memory utilization exceeds ${var.alarm_memory_threshold}% for ${var.alarm_evaluation_periods} consecutive periods"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  datapoints_to_alarm = var.alarm_evaluation_periods
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.alarm_memory_threshold
  treat_missing_data  = "notBreaching"

  dimensions = local.eks_dimensions

  alarm_actions = local.alarm_actions
  ok_actions    = local.ok_actions

  tags = merge(local.common_tags, {
    Alarm = "eks-memory-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "eks_node_not_ready" {
  count = var.enable_eks_alarms ? 1 : 0

  alarm_name          = "${local.alarm_name_prefix}-eks-node-not-ready"
  alarm_description   = "One or more EKS nodes are in NotReady state"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "node_status_condition_ready"
  namespace           = "ContainerInsights"
  period              = var.alarm_period
  statistic           = "Minimum"
  threshold           = 0
  treat_missing_data  = "breaching"

  dimensions = local.eks_dimensions

  alarm_actions = local.alarm_actions
  ok_actions    = local.ok_actions

  tags = merge(local.common_tags, {
    Alarm = "eks-node-not-ready"
  })
}

resource "aws_cloudwatch_metric_alarm" "eks_pod_restart" {
  count = var.enable_eks_alarms ? 1 : 0

  alarm_name          = "${local.alarm_name_prefix}-eks-pod-restarts"
  alarm_description   = "High pod restart rate (>10 restarts in period) in EKS cluster"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "pod_number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.alarm_pod_restart_threshold
  treat_missing_data  = "notBreaching"

  dimensions = local.eks_dimensions

  alarm_actions = local.alarm_actions
  ok_actions    = local.ok_actions

  tags = merge(local.common_tags, {
    Alarm = "eks-pod-restarts"
  })
}

# -----------------------------------------------------------------------------
# Composite Alarm — Node Health
# -----------------------------------------------------------------------------
# Fires only when BOTH cpu AND memory are high, or when a node is NotReady.
# Reduces noise from brief spikes.

resource "aws_cloudwatch_composite_alarm" "eks_node_health" {
  count = var.enable_eks_alarms ? 1 : 0

  alarm_name        = "${local.alarm_name_prefix}-eks-node-health"
  alarm_description = "EKS node health degraded — check node readiness or sustained resource pressure"

  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.eks_node_not_ready[0].alarm_name})",
    "(ALARM(${aws_cloudwatch_metric_alarm.eks_cpu[0].alarm_name}) AND ALARM(${aws_cloudwatch_metric_alarm.eks_memory[0].alarm_name}))",
  ])

  alarm_actions = local.alarm_actions
  ok_actions    = local.ok_actions

  tags = merge(local.common_tags, {
    Alarm = "eks-node-health"
  })
}
