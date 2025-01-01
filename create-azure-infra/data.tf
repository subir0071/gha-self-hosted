
# Azure Container Instance Contributor Role Definition
data "azurerm_role_definition" "aci_contributor" {
  name = "Azure Container Instances Contributor Role"
}

data "azurerm_role_definition" "akv_reader" {
  name = "Key Vault Contributor"  # Role name"
}

data "azurerm_client_config" "current" {}

