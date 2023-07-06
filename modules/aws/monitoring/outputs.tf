output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = local.sns_topic_arn
}

output "sns_topic_name" {
  description = "Name of the SNS alerts topic"
  value       = var.sns_topic_arn == null ? aws_sns_topic.alerts[0].name : null
}

output "eks_alarm_arns" {
  description = "ARNs of EKS CloudWatch alarms"
  value = var.enable_eks_alarms ? [
    aws_cloudwatch_metric_alarm.eks_cpu[0].arn,
    aws_cloudwatch_metric_alarm.eks_memory[0].arn,
    aws_cloudwatch_metric_alarm.eks_node_not_ready[0].arn,
    aws_cloudwatch_metric_alarm.eks_pod_restart[0].arn,
  ] : []
}
