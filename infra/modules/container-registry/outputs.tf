output "login_server" {
  description = "ACR login server URL (without https://)"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  description = "ACR resource ID for RBAC assignments"
  value       = azurerm_container_registry.acr.id
}