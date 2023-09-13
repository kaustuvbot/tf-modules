# Azure Stack Composition for Platform Blueprint
# Wires resource-group + vnet + aks + monitoring into a coherent stack

module "azure_stack" {
  count  = local.is_azure ? 1 : 0
  source = "./azure-stack"

  project                = var.project
  environment            = var.environment
  location               = var.azure_config.location
  vnet_cidr              = var.azure_config.vnet_cidr
  kubernetes_version     = var.azure_config.kubernetes_version
  enable_private_cluster = var.azure_config.enable_private_cluster
  tags                   = local.common_tags
}
