variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure location where resources will be created"
  type        = string
}

variable "org_service_url" {
  description = "Azure DevOps Organization Service URL"
  type        = string
}
variable "personal_access_token" {
  description = "Personal Access Token for Azure DevOps"
  type        = string
  sensitive   = true
}
variable "container_registry_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}
variable "devops_conn_registry_name"{
  description = "Name of the Devops connection to the Azure Container Registry"
  type        = string
}
variable "project_id"{
  description = "id of the current project"
  type        = string
}
variable "agent_pool_name"{
  description = "Name of the agent pool in the new project"
  type        = string
}
variable "service_principal_id" { 
  type        = string
  description = "ID of the service principal for the Azure Container Registry"
}
variable "service_principal_key" {
  type        = string
  sensitive   = true
 }
variable "tenant_id" {
  description = "ID of the tenant where the Azure Container Registry is located"
  type        = string
 }
variable "subscription_id" {
  description = "ID of the subscription where the Azure Container Registry is located"
  type        = string
 }
variable "subscription_name" {
  description = "Name of the agent pool in the new project"
  type        = string
  default    = "Azure subscription"
}
variable "permission_file" {
  description = "Name of the script that sets pipeline permissions"
  type        = string
}