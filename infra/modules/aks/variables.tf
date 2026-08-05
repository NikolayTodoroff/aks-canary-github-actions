variable "prefix" {
  description = "Resource naming prefix"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster and node pools"
  type        = string
  default     = "1.35.5"
}

variable "system_node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 1
}

variable "system_node_vm_size" {
  description = "VM size for system node pool nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "vnet_subnet_id" {
  description = "Subnet ID for the AKS node pools"
  type        = string
}

variable "admin_group_object_ids" {
  description = "Azure AD group Object IDs granted cluster-admin access"
  type        = list(string)
}

variable "user_node_count" {
  description = "Number of nodes in the user node pool"
  type        = number
  default     = 1
}

variable "user_node_vm_size" {
  description = "VM size for user node pool nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Container Insights"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}