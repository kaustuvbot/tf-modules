provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "example-front-door-aks-rg"
  location = "eastus"
}

resource "azurerm_resource_group" "aks" {
  name     = "example-aks-rg"
  location = "eastus"
}

module "vnet" {
  source = "../../modules/azure/vnet"

  project             = "example"
  environment         = "dev"
  resource_group_name = azurerm_resource_group.aks.name
  location           = azurerm_resource_group.aks.location

  address_space = ["10.0.0.0/16"]

  subnets = {
    "aks-system" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "aks-apps" = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
}

module "aks" {
  source = "../../modules/azure/aks"

  project             = "example"
  environment         = "dev"
  location           = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  kubernetes_version = "1.28"

  system_node_pool_subnet_id = module.vnet.subnet_ids["aks-system"]

  private_cluster_enabled = true
  workload_identity_enabled = true
  azure_policy_enabled    = true

  tags = {
    Example = "front-door-aks"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = module.aks.cluster_id
  vm_size              = "Standard_D2s_v3"
  node_count           = 2

  vnet_subnet_id = module.vnet.subnet_ids["aks-apps"]
}

# Private DNS zone for AKS private endpoints
module "private_dns" {
  source = "../../modules/azure/private-dns"

  project             = "example"
  environment         = "dev"
  resource_group_name = azurerm_resource_group.aks.name

  dns_zones = {
    "internal" = {
      zone_name = "internal.example.com"
    }
  }

  links = {
    "aks-vnet" = {
      vnet_id             = module.vnet.vnet_id
      registration_enabled = true
    }
  }
}

# Front Door pointing to AKS via Application Gateway
module "front_door" {
  source = "../../modules/azure/front-door"

  project             = "example"
  environment         = "dev"
  resource_group_name = azurerm_resource_group.main.name
  sku_name           = "Premium_AzureFrontDoor"

  origins = {
    "primary-aks" = {
      host_name = module.aks.application_gateway_ip_configuration
      priority  = 1
      weight    = 100
    }
    "secondary-aks" = {
      host_name = "example-backup.eastus.cloudapp.azure.com"
      priority  = 2
      weight    = 100
    }
  }

  routes = {
    "api" = {
      patterns_to_match    = ["/api/*"]
      supported_protocols = ["Https"]
      cache_enabled      = false
    }
    "default" = {
      patterns_to_match   = ["/*"]
      supported_protocols = ["Http", "Https"]
    }
  }

  health_probe = {
    interval_in_seconds = 30
    path             = "/healthz"
    protocol         = "Https"
  }

  tags = {
    Example = "front-door-aks"
  }
}
