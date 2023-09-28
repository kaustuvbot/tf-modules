output "registry_id" {
  description = "Resource ID of the Azure Container Registry"
  value       = azurerm_container_registry.this.id
}

output "registry_name" {
  description = "Name of the Azure Container Registry (alphanumeric, used as the Docker registry hostname prefix)"
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Login server URL of the registry (e.g. myprojectdev.azurecr.io). Use as the image registry hostname in Kubernetes pod specs."
  value       = azurerm_container_registry.this.login_server
}

output "resource_group_name" {
  description = "Resource group containing the registry"
  value       = azurerm_container_registry.this.resource_group_name
}
