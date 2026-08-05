resource "azurerm_resource_group" "rg_main" {
  name     = "rg-main-${local.prefix}"
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

module "networking" {
  source = "../modules/networking"

  prefix              = local.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_main.name
  tags                = local.common_tags
}

module "container_registry" {
  source = "../modules/container-registry"

  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.rg_main.name
  location            = var.location
  tags                = local.common_tags
}

module "aks" {
  source = "../modules/aks"

  prefix                 = local.prefix
  location               = var.location
  resource_group_name    = azurerm_resource_group.rg_main.name
  dns_prefix             = local.prefix
  vnet_subnet_id         = module.networking.aks_subnet_id
  admin_group_object_ids = [var.aks_admin_group_object_id]
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                   = local.common_tags
}

module "monitoring" {
  source = "../modules/monitoring"

  prefix              = local.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_main.name
  tags                = local.common_tags
}

