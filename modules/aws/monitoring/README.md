# AWS Monitoring Module

CloudWatch alarms and SNS notification infrastructure for EKS clusters. Creates an SNS topic (or accepts an existing one) and optional CloudWatch alarms for CPU, memory, node health, pod restarts, and pending pods.

## Usage

```hcl
module "monitoring" {
  source = "../../modules/aws/monitoring"

  project     = "myproject"
  environment = "prod"

  cluster_name       = module.eks.cluster_name
  enable_eks_alarms  = true

  alarm_email_addresses = ["alerts@example.com"]

  tags = {
    CostCenter = "platform"
  }
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name for naming and tagging |
| `environment` | `string` | — | Environment (`dev`, `staging`, `prod`) |
| `cluster_name` | `string` | `""` | EKS cluster name used in alarm metric dimensions |
| `enable_eks_alarms` | `bool` | `false` | Create EKS CloudWatch alarms (CPU, memory, nodes, restarts, pending pods) |
| `sns_topic_arn` | `string` | `null` | Existing SNS topic ARN; a new topic is created if null |
| `alarm_cpu_threshold` | `number` | `80` | CPU utilization % threshold |
| `alarm_memory_threshold` | `number` | `80` | Memory utilization % threshold |
| `alarm_evaluation_periods` | `number` | `3` | Number of evaluation periods before alarm fires |
| `alarm_period` | `number` | `300` | Evaluation period in seconds |
| `alarm_pod_restart_threshold` | `number` | `10` | Pod restart count threshold per period |
| `alarm_pending_pods_threshold` | `number` | `5` | Pending pod count threshold |
| `alarm_email_addresses` | `list(string)` | `[]` | Email addresses to subscribe to the SNS topic |
| `slack_webhook_url` | `string` | `null` | Slack webhook URL for alarm notifications (sensitive) |
| `slack_channel` | `string` | `"#alerts"` | Slack channel for notifications |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `sns_topic_arn` | ARN of the SNS topic (created or provided) |
| `sns_topic_name` | Name of the created SNS topic (null if an existing topic was provided) |
| `eks_alarm_arns` | List of EKS CloudWatch alarm ARNs (empty if `enable_eks_alarms=false`) |

## Notes

- The SNS topic is created in the same region as the provider. Pass `sns_topic_arn` to reuse a cross-account or pre-existing topic.
- EKS alarms use Container Insights metrics (`ContainerInsights` namespace). Ensure Container Insights is enabled on the cluster.
- Slack notifications use a Lambda-backed SNS subscription. `slack_webhook_url` is marked sensitive and should be passed via a secret or SSM parameter.
