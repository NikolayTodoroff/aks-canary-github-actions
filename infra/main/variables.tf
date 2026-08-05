
variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "aks_admin_group_object_id" {
  description = "Object ID of the Azure AD group granted cluster-admin access"
  type        = string
}

variable "pipeline_sp_object_id" {
  description = "Object ID of the service principal used by the CI/CD pipeline"
  type        = string
}
