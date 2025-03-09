resource "azurerm_resource_group" "gha_runner_rg" {
  name     = "${var.project}-${var.env}-rg"
  location = var.location
}

# Storage Account
resource "azurerm_storage_account" "gha_runner_sa" {
  name                     = "${var.project}${var.env}" # Unique name for the storage account
  resource_group_name      = azurerm_resource_group.gha_runner_rg.name
  location                 = azurerm_resource_group.gha_runner_rg.location
  account_tier             = var.storage_account_account_tier #"Standard"
  account_replication_type = var.storage_account_replication_type #"LRS"
  account_kind             = "Storage"
}

# App Service Plan (Hosting plan for the function app)
resource "azurerm_service_plan" "gha_runner_asp" {
  name                = "${var.project}-${var.env}-asp"
  resource_group_name = azurerm_resource_group.gha_runner_rg.name
  location            = var.location
   os_type            = "Linux"
   sku_name           = var.app_service_plan_sku_name
}

resource "azurerm_linux_function_app" "gha_runner_receiver_function_app" {
  name                        = "${var.project}-${var.env}-receiver-function-app"
  resource_group_name         = azurerm_resource_group.gha_runner_rg.name
  location                    = var.location
  service_plan_id             = azurerm_service_plan.gha_runner_asp.id
  storage_account_name        = azurerm_storage_account.gha_runner_sa.name
  storage_account_access_key  = azurerm_storage_account.gha_runner_sa.primary_access_key
  https_only                  = true
  functions_extension_version = "~4"

  app_settings = {
    "AZURE_SUBSCRIPTION_ID"           = data.azurerm_client_config.current.subscription_id
    "AZURE_RESOURCE_GROUP"            = azurerm_resource_group.gha_runner_rg.name
    "ENABLE_ORYX_BUILD"              = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "AzureWebJobsFeatureFlags"       = "EnableWorkerIndexing"
    "QUEUE_NAME"                     = azurerm_storage_queue.gh_runner_asq.name
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.gha_runner_aai.instrumentation_key
    "storageAccountConnectionString"  = azurerm_storage_account.gha_runner_sa.primary_connection_string
    "WEBSITE_RUN_FROM_PACKAGE"         = "1" 
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  # identity {
  #   type = "SystemAssigned"
  # }

}

resource "azurerm_linux_function_app" "gha_runner_controller_function_app" {
  name                        = "${var.project}-${var.env}-controller-function-app"
  resource_group_name         = azurerm_resource_group.gha_runner_rg.name
  location                    = var.location
  service_plan_id             = azurerm_service_plan.gha_runner_asp.id
  storage_account_name        = azurerm_storage_account.gha_runner_sa.name
  storage_account_access_key  = azurerm_storage_account.gha_runner_sa.primary_access_key
  https_only                  = false
  functions_extension_version = "~4"

  app_settings = {
    "AZURE_CONTAINER_REGISTRY"        = azurerm_container_registry.gha_runner_acr.name
    "AZURE_KV_NAME"                   = azurerm_key_vault.gha_runner_kv.name
    "AZURE_ACR_USER"                  = azurerm_key_vault_secret.gha_kv_acr_username.name
    "AZURE_ACR_PASS"                  = azurerm_key_vault_secret.gha_kv_acr_pass.name
    "GH_APP_PEM_FILE"                 = azurerm_key_vault_secret.gha_kv_gh_pemfile.name
    "GH_APP_CLIENT_ID_KEY"            = azurerm_key_vault_secret.gha_kv_gh_app_clientid.name
    "GH_APP_INSTT_ID_KEY"             = azurerm_key_vault_secret.gha_kv_gh_instt_id.name
    "GH_ORG_NAME"                     = var.GITHUB_ORG_NAME 
    "AZURE_SUBSCRIPTION_ID"           = data.azurerm_client_config.current.subscription_id
    "AZURE_RESOURCE_GROUP"            = azurerm_resource_group.gha_runner_rg.name
    "AZURE_LOCATION"                  = var.location
    "FUNCTIONS_WORKER_RUNTIME"        = "python"
    "AzureWebJobsFeatureFlags"        = "EnableWorkerIndexing"
    "QUEUE_NAME"                      = azurerm_storage_queue.gh_runner_asq.name
    "APPINSIGHTS_INSTRUMENTATIONKEY"  = azurerm_application_insights.gha_runner_aai.instrumentation_key
    "storageAccountConnectionString"  = azurerm_storage_account.gha_runner_sa.primary_connection_string
    "WEBSITE_RUN_FROM_PACKAGE"        = "1" 
    "ENABLE_ORYX_BUILD"              = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_role_assignment" "gha_controller_fn_ra" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = data.azurerm_role_definition.aci_contributor.name
  principal_id         = azurerm_linux_function_app.gha_runner_controller_function_app.identity[0].principal_id
}

resource "azurerm_role_assignment" "keyvault_secrets_user" {
  scope                = azurerm_key_vault.gha_runner_kv.id
  role_definition_name = data.azurerm_role_definition.akv_reader.name
  principal_id         = azurerm_linux_function_app.gha_runner_controller_function_app.identity[0].principal_id
}

# Azure Storage Queue
resource "azurerm_storage_queue" "gh_runner_asq" {
  name                 = "${var.project}-${var.env}-queue"
  storage_account_name = azurerm_storage_account.gha_runner_sa.name
}

# # Application Insights (Optional)
 resource "azurerm_application_insights" "gha_runner_aai" {
  name                = "${var.project}-${var.env}-app-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.gha_runner_rg.name
  application_type    = "other"
 }

resource "azurerm_container_registry" "gha_runner_acr" {
  name                = "${var.project}${var.env}acr"
  resource_group_name = azurerm_resource_group.gha_runner_rg.name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = true
}

resource "azurerm_key_vault" "gha_runner_kv" {
  name                       = "${var.project}-${var.env}-kv"
  location                   = azurerm_resource_group.gha_runner_rg.location
  resource_group_name        = azurerm_resource_group.gha_runner_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.kv_sku_name
  soft_delete_retention_days = 7
  enable_rbac_authorization = true
}

resource "azurerm_key_vault_secret" "gha_kv_gh_app_id" {
  name         = "${var.project}-${var.env}-kv-gh-appid"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  var.GITHUB_APP_ID
}

resource "azurerm_key_vault_secret" "gha_kv_gh_instt_id" {
  name         = "${var.project}-${var.env}-kv-gh-insttid"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  var.GITHUB_APP_INSTALLATION_ID
}

resource "azurerm_key_vault_secret" "gha_kv_gh_pemfile" {
  name         = "${var.project}-${var.env}-kv-gh-pemfile"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  var.GITHUB_APP_PEM_FILE
}

resource "azurerm_key_vault_secret" "gha_kv_gh_app_clientid" {
  name         = "${var.project}-${var.env}-kv-gh-app-clientid"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  var.GITHUB_APP_CLIENTID
}

resource "azurerm_key_vault_secret" "gha_kv_acr_username" {
  name         = "${var.project}-${var.env}-kv-acr-username"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  azurerm_container_registry.gha_runner_acr.admin_username
}

resource "azurerm_key_vault_secret" "gha_kv_acr_pass" {
  name         = "${var.project}-${var.env}-kv-acr-pass"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  azurerm_container_registry.gha_runner_acr.admin_password
}


resource "azurerm_linux_function_app" "gha_runner_cleanup_function_app" {
  name                        = "${var.project}-${var.env}-cleanup-function-app"
  resource_group_name         = azurerm_resource_group.gha_runner_rg.name
  location                    = var.location
  service_plan_id             = azurerm_service_plan.gha_runner_asp.id
  storage_account_name        = azurerm_storage_account.gha_runner_sa.name
  storage_account_access_key  = azurerm_storage_account.gha_runner_sa.primary_access_key
  https_only                  = false
  functions_extension_version = "~4"

  app_settings = {
    # "AZURE_CONTAINER_REGISTRY"        = azurerm_container_registry.gha_runner_acr.name
    # "AZURE_KV_NAME"                   = azurerm_key_vault.gha_runner_kv.name
    # "AZURE_ACR_USER"                  = azurerm_key_vault_secret.gha_kv_acr_username.name
    # "AZURE_ACR_PASS"                  = azurerm_key_vault_secret.gha_kv_acr_pass.name
    # "GH_APP_PEM_FILE"                 = azurerm_key_vault_secret.gha_kv_gh_pemfile.name
    # "GH_APP_CLIENT_ID_KEY"            = azurerm_key_vault_secret.gha_kv_gh_app_clientid.name
    # "GH_APP_INSTT_ID_KEY"             = azurerm_key_vault_secret.gha_kv_gh_instt_id.name
    # "GH_ORG_NAME"                     = var.GITHUB_ORG_NAME 
    "AZURE_SUBSCRIPTION_ID"           = data.azurerm_client_config.current.subscription_id
    "AZURE_RESOURCE_GROUP"            = azurerm_resource_group.gha_runner_rg.name
    "AZURE_LOCATION"                  = var.location
    "FUNCTIONS_WORKER_RUNTIME"        = "python"
    "AzureWebJobsFeatureFlags"        = "EnableWorkerIndexing"
    "APPINSIGHTS_INSTRUMENTATIONKEY"  = azurerm_application_insights.gha_runner_aai.instrumentation_key
    "storageAccountConnectionString"  = azurerm_storage_account.gha_runner_sa.primary_connection_string
    "WEBSITE_RUN_FROM_PACKAGE"        = "1" 
    "ENABLE_ORYX_BUILD"              = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
  identity {
    type = "SystemAssigned"
  }
}