resource "random_string" "resource_code" {
  length  = 5
  special = false
  upper   = false
}

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
    "ENABLE_ORYX_BUILD"              = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "AzureWebJobsFeatureFlags"       = "EnableWorkerIndexing"
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
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
    "ENABLE_ORYX_BUILD"              = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "AzureWebJobsFeatureFlags"       = "EnableWorkerIndexing"
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
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
}


resource "random_id" "gha_key_vault_key_id" {
  byte_length = 4
   
}

resource "azurerm_key_vault" "gha_runner_kv" {
  name                       = "${var.project}-${var.env}-kv"
  location                   = azurerm_resource_group.gha_runner_rg.location
  resource_group_name        = azurerm_resource_group.gha_runner_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.kv_sku_name
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "Set", "Get", "List", "Delete", "Purge",
    ]
  }
}

resource "azurerm_key_vault_secret" "gha_kv_gh_app_id" {
  name         = "${var.project}-${var.env}-kv-gh-appid"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  var.GITHUB_APP_ID

  lifecycle {
    ignore_changes = [value] # Prevent Terraform from overwriting the existing value
  }

}

resource "azurerm_key_vault_secret" "gha_kv_gh_instt_id" {
  name         = "${var.project}-${var.env}-kv-gh-insttid"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  var.GITHUB_APP_INSTALLATION_ID

   lifecycle {
    ignore_changes = [value] 
  }
}

resource "azurerm_key_vault_secret" "gha_kv_gh_pemfile" {
  name         = "${var.project}-${var.env}-kv-gh-pemfile"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  var.GITHUB_APP_PEM_FILE

   lifecycle {
    ignore_changes = [value] 
  }
}

resource "azurerm_key_vault_secret" "gha_kv_gh_app_clientid" {
  name         = "${var.project}-${var.env}-kv-gh-app-clientid"
  key_vault_id = azurerm_key_vault.gha_runner_kv.id
  value =  var.GITHUB_APP_CLIENTID

   lifecycle {
    ignore_changes = [value]
  }
}
