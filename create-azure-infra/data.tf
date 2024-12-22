
# Azure Container Instance Contributor Role Definition
data "azurerm_role_definition" "aci_contributor" {
  name = "Azure Container Instance Contributor"
}

data "azurerm_client_config" "current" {}