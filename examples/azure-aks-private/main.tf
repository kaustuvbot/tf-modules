# Private AKS cluster example with private-dns zone and key-vault integration

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "resource_group" {
  source      = "../../modules/azure/resource-group"
  project     = var.project
  environment = var.environment
  location    = var.location
  tags        = local.tags
}

module "vnet" {
  source              = "../../modules/azure/vnet"
  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  vnet_cidr           = "10.0.0.0/16"
  subnets = {
    aks = { cidr = "10.0.1.0/24" }
  }
  tags = local.tags
}

module "private_dns" {
  source              = "../../modules/azure/private-dns"
  project             = var.project
  environment         = var.environment
  resource_group_name = module.resource_group.name
  vnet_id             = module.vnet.vnet_id
  tags                = local.tags
}

module "aks" {
  source              = "../../modules/azure/aks"
  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  vnet_subnet_id      = module.vnet.subnet_ids["aks"]
  dns_zone_id         = module.private_dns.zone_id
  kubernetes_version  = "1.29"
  enable_private_cluster = true
  tags                = local.tags
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Example     = "azure-aks-private"
  }
}
