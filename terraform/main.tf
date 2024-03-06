terraform {
  backend "azurerm" {
  }
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.11.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}
# devops provider to create:
# * agent pool and agent queue
# * authorization for the agent pool
# * connection from project to acr

provider "azuredevops" {
  org_service_url = var.org_service_url
  personal_access_token = var.personal_access_token
}

provider "azurerm" {
  features {}
}