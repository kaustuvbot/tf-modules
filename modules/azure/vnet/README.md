# Azure VNet Module

Manages an Azure Virtual Network with per-subnet Network Security Groups,
an optional deny-all egress rule, DDoS Protection Standard attachment, and
NSG flow log integration.

## Usage

```hcl
module "vnet" {
  source = "../../modules/azure/vnet"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.10.0.0/16"]

  subnets = {
    "aks-system" = {
      address_prefixes    = ["10.10.1.0/24"]
      deny_internet_egress = true
    }
    "aks-apps" = {
      address_prefixes    = ["10.10.2.0/24"]
      deny_internet_egress = false
    }
    "appgw" = {
      address_prefixes    = ["10.10.3.0/24"]
      deny_internet_egress = false
    }
  }

  ddos_protection_plan_id = azurerm_network_ddos_protection_plan.main.id

  enable_flow_logs                        = true
  flow_log_storage_account_id             = azurerm_storage_account.logs.id
  flow_log_network_watcher_name           = "NetworkWatcher_eastus"
  flow_log_network_watcher_resource_group = "NetworkWatcherRG"

  tags = {
    Team = "platform"
  }
}
```

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `project` | `string` | Project name (2–24 lowercase alphanumeric or hyphens) |
| `environment` | `string` | Environment: `dev`, `staging`, or `prod` |
| `resource_group_name` | `string` | Resource group to deploy into |
| `location` | `string` | Azure region |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `address_space` | `list(string)` | `["10.0.0.0/16"]` | VNet address space (at least one CIDR) |
| `subnets` | `map(object)` | `{}` | Map of subnet name to configuration (see below) |
| `ddos_protection_plan_id` | `string` | `null` | Attach DDoS Protection Standard plan resource ID |
| `enable_flow_logs` | `bool` | `false` | Enable NSG flow logs for all subnets |
| `flow_log_storage_account_id` | `string` | `null` | Storage account for flow logs (required when enabled) |
| `flow_log_network_watcher_name` | `string` | `null` | Network Watcher name (required when enabled) |
| `flow_log_network_watcher_resource_group` | `string` | `null` | Network Watcher resource group (required when enabled) |
| `tags` | `map(string)` | `{}` | Additional tags |

### subnets object shape

```hcl
subnets = {
  "subnet-name" = {
    address_prefixes     = ["10.0.1.0/24"]  # required
    deny_internet_egress = false             # optional, default false
    service_endpoints    = []               # optional, list of Azure service endpoints
    delegations          = []               # optional, service delegation blocks
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | Resource ID of the VNet |
| `vnet_name` | Name of the VNet |
| `address_space` | Address space list of the VNet |
| `subnet_ids` | Map of subnet name to subnet resource ID |
| `nsg_ids` | Map of subnet name to NSG resource ID |

## NSG Design

Each subnet gets its own NSG, automatically associated at creation. The NSG model:

- **Default rules**: Azure's built-in AllowVNetInBound / AllowAzureLoadBalancerInBound / DenyAllInBound apply at priority 65xxx.
- **Deny egress**: Setting `deny_internet_egress = true` on a subnet adds a priority-4000 outbound rule blocking `Internet` traffic. Private VNet-to-VNet traffic is unaffected.
- All custom rules should use priorities in the 100–3999 range to remain above the deny rule.

## Security Notes

- `ddos_protection_plan_id` enables Azure DDoS Protection Standard, which provides adaptive tuning and real-time attack mitigation. Requires a separately provisioned plan resource (billed per VNet).
- `enable_flow_logs` captures source/dest IP, port, protocol, and allowed/denied state for all NSG-matched traffic. Required for security incident investigation and compliance audits.
- Use `deny_internet_egress = true` on subnets hosting AKS system/user pools to enforce egress through an Azure Firewall or NAT Gateway rather than direct internet breakout.
