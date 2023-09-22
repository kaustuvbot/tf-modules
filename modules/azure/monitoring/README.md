# Azure Monitoring Module

Manages Azure Monitor metric alerts for an AKS cluster, including CPU and
memory usage thresholds with optional email action group notifications.

## Usage

```hcl
module "monitoring" {
  source = "../../modules/azure/monitoring"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  aks_cluster_id      = module.aks.cluster_id

  action_group_email       = "platform-alerts@example.com"
  cpu_threshold_percent    = 75
  memory_threshold_percent = 80

  tags = {
    Team = "platform"
  }
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name (2–24 lowercase alphanumeric or hyphens) |
| `environment` | `string` | — | Environment: `dev`, `staging`, or `prod` |
| `resource_group_name` | `string` | — | Resource group to deploy into |
| `location` | `string` | — | Azure region |
| `aks_cluster_id` | `string` | — | Resource ID of the AKS cluster to monitor |
| `action_group_email` | `string` | `null` | Email address for alert notifications (null = no email action group) |
| `cpu_threshold_percent` | `number` | `80` | CPU usage % threshold to trigger alert |
| `memory_threshold_percent` | `number` | `80` | Memory working set % threshold to trigger alert |
| `tags` | `map(string)` | `{}` | Additional tags |

## Alerts Created

| Alert | Metric | Threshold |
|-------|--------|-----------|
| CPU | `cpuUsagePercentage` | `cpu_threshold_percent` |
| Memory | `memoryWorkingSetPercentage` | `memory_threshold_percent` |

Both alerts use a 5-minute evaluation window and trigger when the metric
exceeds the threshold for 1 consecutive period.

## Notes

- This module creates metric alerts scoped to the AKS cluster resource.
- When `action_group_email` is set, an Azure Monitor action group is created
  and linked to both alerts.
- For production environments, consider lowering thresholds (e.g., 70% CPU)
  to provide runway before saturation.
