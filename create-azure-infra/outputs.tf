output "receiver_function_app_name" {
  value = azurerm_linux_function_app.gha_runner_receiver_function_app.name
  description = "Deployed receiver function app name"
}

output "controller_function_app_name" {
  value = azurerm_linux_function_app.gha_runner_controller_function_app.name
  description = "Deployed controller function app name"
}

output "queue_name" {
  value = azurerm_storage_queue.gh_runner_asq.name
  description = "Queue storage name"
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.gha_runner_receiver_function_app.default_hostname
  description = "Deployed function app hostname"
}

# output "resource_group" {
#   value = azurerm_resource_group.gha_runner_rg.name
#   description = "Name of the resource group"
# }

