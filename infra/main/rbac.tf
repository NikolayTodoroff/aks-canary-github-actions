resource "azurerm_role_assignment" "acr_kubernetes_pull" {
  scope                = module.container_registry.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

resource "azurerm_role_assignment" "acr_pipeline_push" {
  scope                = module.container_registry.acr_id
  role_definition_name = "AcrPush"
  principal_id         = var.pipeline_sp_object_id
}

resource "azurerm_role_assignment" "aks_pipeline_admin" {
  scope                = module.aks.cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = var.pipeline_sp_object_id
}

resource "azurerm_role_assignment" "aks_pipeline_rbac_admin" {
  scope                = module.aks.cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.pipeline_sp_object_id
}