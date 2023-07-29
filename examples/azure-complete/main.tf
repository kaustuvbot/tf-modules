# -----------------------------------------------------------------------------
# Example: Azure Complete Stack
# -----------------------------------------------------------------------------
# Demonstrates how to compose the Azure modules into a full environment:
#   Resource Group → VNet → AKS → Key Vault → Monitoring
# -----------------------------------------------------------------------------

module "rg" {
  source      = "../../modules/azure/resource-group"
  project     = var.project
  environment = var.environment
  location    = var.location
  tags        = var.tags
}

module "vnet" {
  source              = "../../modules/azure/vnet"
  project             = var.project
  environment         = var.environment
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = ["10.10.0.0/16"]

  subnets = {
    aks-system = {
      address_prefixes  = ["10.10.1.0/24"]
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
    aks-user = {
      address_prefixes = ["10.10.2.0/24"]
    }
  }

  tags = var.tags
}

module "aks" {
  source              = "../../modules/azure/aks"
  project             = var.project
  environment         = var.environment
  resource_group_name = module.rg.name
  location            = module.rg.location

  system_node_pool_subnet_id  = module.vnet.subnet_ids["aks-system"]
  system_node_pool_vm_size    = "Standard_D4s_v3"
  system_node_pool_node_count = 2
  system_node_pool_min_count  = 2
  system_node_pool_max_count  = 5

  private_cluster_enabled = var.environment == "prod"

  tags = var.tags
}

module "kv" {
  source              = "../../modules/azure/key-vault"
  project             = var.project
  environment         = var.environment
  resource_group_name = module.rg.name
  location            = module.rg.location
  tenant_id           = var.tenant_id
  tags                = var.tags
}

module "monitoring" {
  source              = "../../modules/azure/monitoring"
  project             = var.project
  environment         = var.environment
  resource_group_name = module.rg.name
  location            = module.rg.location
  aks_cluster_id      = module.aks.cluster_id
  action_group_email  = var.alert_email
  tags                = var.tags
}
