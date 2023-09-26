# Azure Front Door Module

Manages an Azure Front Door CDN profile with endpoints, origin groups, origins,
routing rules, and optional WAF security policy integration.

## Usage

```hcl
module "front_door" {
  source = "../../modules/azure/front-door"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  sku_name           = "Standard_AzureFrontDoor"

  origins = {
    "primary" = {
      host_name = "myapp.azurewebsites.net"
      priority  = 1
      weight    = 100
    }
    "secondary" = {
      host_name = "myapp-backup.azurewebsites.net"
      priority  = 2
      weight    = 100
    }
  }

  routes = {
    "default" = {
      patterns_to_match   = ["/*"]
      supported_protocols = ["Http", "Https"]
    }
  }

  health_probe = {
    interval_in_seconds = 30
    path               = "/health"
    protocol           = "Https"
  }

  tags = {
    Team = "platform"
  }
}
```

### With WAF Integration

```hcl
module "front_door_with_waf" {
  source = "../../modules/azure/front-door"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  sku_name           = "Premium_AzureFrontDoor"

  origins = {
    "api" = {
      host_name = "api.myapp.com"
    }
  }

  routes = {
    "api" = {
      patterns_to_match   = ["/api/*"]
      supported_protocols = ["Https"]
    }
  }

  security_policies = {
    "waf-policy" = {
      waf_policy_id = azurerm_cdn_frontdoor_waf_policy.main.id
    }
  }
}
```

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `project` | `string` | Project name (2–24 lowercase alphanumeric or hyphens) |
| `environment` | `string` | Environment: `dev`, `staging`, or `prod` |
| `resource_group_name` | `string` | Resource group to deploy Front Door into |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `sku_name` | `string` | `Standard_AzureFrontDoor` | Front Door SKU: `Standard_AzureFrontDoor` or `Premium_AzureFrontDoor` |
| `origins` | `map(object)` | `{}` | Map of origin configurations (see below) |
| `routes` | `map(object)` | `{}` | Map of routing rule configurations (see below) |
| `security_policies` | `map(object)` | `{}` | Map of security policy configurations (see below) |
| `health_probe` | `object` | (see below) | Health probe and load balancing settings |
| `tags` | `map(string)` | `{}` | Additional tags |

### origins object shape

```hcl
origins = {
  "origin-name" = {
    host_name          = "example.azurewebsites.net"  # required
    http_port          = 80                            # optional, default 80
    https_port         = 443                           # optional, default 443
    origin_host_header = null                           # optional, defaults to host_name
    priority           = 1                              # optional, default 1 (for failover)
    weight             = 1000                          # optional, default 1000
    enabled            = true                          # optional, default true
  }
}
```

### routes object shape

```hcl
routes = {
  "route-name" = {
    patterns_to_match           = ["/*"]                    # required
    supported_protocols         = ["Http", "Https"]        # required
    forwarding_protocol         = "HttpsOnly"              # optional, default HttpsOnly
    https_redirect_enabled      = true                     # optional, default true
    link_to_default_domain      = true                     # optional, default true
    enabled                     = true                     # optional, default true
    cache_enabled                = false                    # optional, default false
    cache_query_string_behavior | "IgnoreQueryString"      # optional
    cache_compression_enabled   = true                     # optional, default true
  }
}
```

### health_probe object shape

```hcl
health_probe = {
  interval_in_seconds            = 30     # optional, default 30
  path                          = "/"    # optional, default "/"
  protocol                      = "Https" # optional, default "Https"
  request_type                  = "HEAD"  # optional, default "HEAD"
  sample_size                   = 4       # optional, default 4
  successful_samples_required   = 3       # optional, default 3
  additional_latency_in_milliseconds = 50 # optional, default 50
}
```

## Outputs

| Name | Description |
|------|-------------|
| `profile_id` | Resource ID of the Front Door profile |
| `profile_name` | Name of the Front Door profile |
| `endpoint_hostname` | Default hostname of the Front Door endpoint |
| `endpoint_id` | Resource ID of the Front Door endpoint |
| `origin_group_id` | Resource ID of the Front Door origin group |
| `origin_ids` | Map of origin IDs by origin name |
| `route_ids` | Map of route IDs by route name |
| `security_policy_ids` | Map of security policy IDs by policy name |

## Architecture

```
                    ┌─────────────────────────────┐
                    │    Front Door Profile       │
                    │   *.azurefd.net endpoint    │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │   Origin Group (primary)    │
                    │  Health Probe → /health     │
                    │  Latency-based routing      │
                    └──────────────┬──────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
   ┌──────────▼──────────┐ ┌──────▼──────┐ ┌─────────▼─────────┐
   │   Origin: primary   │ │ Origin: sec │ │   Origin: backup  │
   │  Priority: 1        │ │ Priority: 2 │ │   Priority: 3     │
   │  Weight: 1000       │ │ Weight: 1000 │ │   Weight: 1000     │
   └─────────────────────┘ └─────────────┘ └────────────────────┘
```

## Security Notes

- WAF integration requires `Premium_AzureFrontDoor` SKU.
- Use `https_redirect_enabled = true` to enforce HTTPS.
- Configure health probe paths to dedicated `/health` endpoints that verify backend availability.
- Origin failover uses priority-based routing when weights are equal.
