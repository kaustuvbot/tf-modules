# Azure Front Door Patterns

Guide for common Azure Front Door architectures and routing patterns.

## Basic Patterns

### Single Origin

```hcl
module "front_door" {
  source = "./modules/azure/front-door"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name

  origins = {
    "webapp" = {
      host_name = "myapp.azurewebsites.net"
      priority  = 1
      weight    = 1000
    }
  }

  routes = {
    "default" = {
      patterns_to_match   = ["/*"]
      supported_protocols = ["Http", "Https"]
    }
  }
}
```

### Multi-Region Failover

```hcl
module "front_door_failover" {
  source = "./modules/azure/front-door"

  project             = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name

  origins = {
    "primary-eastus" = {
      host_name = "myapp-eastus.azurewebsites.net"
      priority  = 1
      weight    = 1000
    }
    "secondary-westus2" = {
      host_name = "myapp-westus2.azurewebsites.net"
      priority  = 2
      weight    = 1000
    }
  }

  routes = {
    "default" = {
      patterns_to_match   = ["/*"]
      supported_protocols = ["Http", "Https"]
    }
  }
}
```

**How it works:**
- Origins with different priorities create failover behavior
- Primary (priority=1) receives all traffic
- Secondary (priority=2) receives traffic when primary is unhealthy
- Health probe at `/` determines origin health

## Routing Patterns

### Path-Based Routing

Route different paths to different origins:

```hcl
routes = {
  "api" = {
    patterns_to_match   = ["/api/*"]
    supported_protocols = ["Https"]
    cache_enabled       = false
  },
  "static" = {
    patterns_to_match    = ["/static/*", "/assets/*"]
    supported_protocols  = ["Https"]
    cache_enabled       = true
    cache_compression_enabled = true
  },
  "default" = {
    patterns_to_match   = ["/*"]
    supported_protocols = ["Http", "Https"]
  }
}
```

### Header-Based Routing

Route based on request headers (requires Premium SKU):

```hcl
# Header-based routing not supported in Terraform directly
# Use Azure Portal or API for header rules
```

## Caching

### Enable Caching for Static Content

```hcl
routes = {
  "static" = {
    patterns_to_match             = ["/*.js", "/*.css", "/*.png", "/*.jpg"]
    supported_protocols           = ["Https"]
    cache_enabled                 = true
    cache_query_string_behavior   = "IgnoreQueryString"  # Cache by path only
    cache_compression_enabled    = true
  }
}
```

### Cache Behavior Options

| Behavior | Use Case |
|----------|----------|
| IgnoreQueryString | Static assets, query params don't change response |
| UseQueryString | API responses that vary by query params |
| IgnoreSpecifiedQueryStrings | Exclude certain params from cache key |
| IncludeSpecifiedQueryStrings | Only use specified params in cache key |

## Security

### WAF Integration (Premium SKU Required)

```hcl
# Create WAF policy
resource "azurerm_cdn_frontdoor_waf_policy" "main" {
  name                = "waf-${var.project}"
  resource_group_name = var.resource_group_name
  mode                = "Prevention"
  redirect_url        = "https://myapp.com"

  custom_rule {
    name     = "Block-IPs"
    priority = 1
    type     = "MatchRule"
    action   = "Block"

    match_condition {
      match_variable     = "RemoteAddr"
      operator          = "IPMatch"
      negation_condition = false
      match_values      = ["1.2.3.4/32"]
    }
  }
}

# Associate with Front Door
module "front_door_with_waf" {
  source = "./modules/azure/front-door"

  # ... other config ...

  security_policies = {
    "waf" = {
      waf_policy_id = azurerm_cdn_frontdoor_waf_policy.main.id
    }
  }
}
```

### HTTPS Enforcement

```hcl
routes = {
  "default" = {
    patterns_to_match    = ["/*"]
    supported_protocols  = ["Http", "Https"]
    https_redirect_enabled = true  # Redirect HTTP to HTTPS
  }
}
```

## Health Probes

### Configure Health Probe

```hcl
health_probe = {
  interval_in_seconds = 30    # Check every 30 seconds
  path              = "/health"  # Health check endpoint
  protocol         = "Https"
  request_type     = "HEAD"
}
```

### Health Endpoint Requirements

Create a `/health` endpoint that:
- Returns 200 OK when healthy
- Returns 503 when unhealthy (or remove from load balancer)
- Has minimal latency (< 100ms)
- Doesn't require authentication

Example for ASP.NET Core:
```csharp
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));
```

### Load Balancing Settings

```hcl
health_probe = {
  interval_in_seconds            = 30
  path                          = "/health"
  protocol                      = "Https"
  request_type                  = "HEAD"
  sample_size                   = 4      # Samples per evaluation
  successful_samples_required    = 3      # Min healthy samples
  additional_latency_in_milliseconds = 50  # Latency sensitivity
}
```

| Setting | Description |
|---------|-------------|
| sample_size | Number of samples to evaluate |
| successful_samples_required | Minimum healthy samples to mark origin healthy |
| additional_latency_in_milliseconds | Latency buffer before switching |

## Cost Optimization

### SKU Comparison

| Feature | Standard | Premium |
|---------|----------|---------|
| Custom domains | 5 | Unlimited |
| WAF | Not available | Included |
| Bot protection | Not available | Included |
| Private origins | Not available | Supported |
| SLA | 99.95% | 99.99% |

### Cost Reduction Tips

1. **Use Standard SKU** unless you need WAF or private origins
2. **Enable caching** to reduce origin requests
3. **Set appropriate health probe intervals** (30s is usually sufficient)
4. **Compress responses** (enabled by default)

## Troubleshooting

### Origin Not Receiving Traffic

1. Check health probe path returns 200
2. Verify priority is lowest for primary
3. Check origin is enabled (`enabled = true`)

### 502/503 Errors

1. Check origin is responding to health probes
2. Verify origin hostname resolves correctly
3. Check origin allows Front Door IP ranges

### Slow Performance

1. Enable caching for static content
2. Enable compression
3. Use Azure Front Door close to users
4. Check origin response time

### SSL/TLS Errors

1. Ensure origin has valid certificate
2. For custom domains, add SSL certificate
3. Check Front Door managed certificate is provisioned
