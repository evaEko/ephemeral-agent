resource "azurerm_container_registry" "terraform_registry_acr" {
  name                = var.container_registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
  depends_on = [ azurerm_resource_group.terraform_rg ]
}
resource "azuredevops_serviceendpoint_azurecr" "acr_service_connection" {
  project_id            = var.project_id
  service_endpoint_name = var.devops_conn_registry_name
  resource_group = var.resource_group_name
  azurecr_spn_tenantid = var.tenant_id
  azurecr_name = var.container_registry_name
  azurecr_subscription_id = var.subscription_id
  azurecr_subscription_name = "DEV_SD_Training"
  depends_on = [azurerm_container_registry.terraform_registry_acr]
}
# sets permissions for the registry service connection
# withtout this, the create-image pipeline requests
# permissions to the registry and you have to approve manually
# in the  create-image pipeline, the value of the pipeline is added
# which seems redundant, but it doesnt work without it
resource "null_resource" "set_service_connection_permissions" {
  depends_on = [azuredevops_serviceendpoint_azurecr.acr_service_connection]
}
