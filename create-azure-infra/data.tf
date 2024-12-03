data "azurerm_function_app_host_keys" "gha_runner_ahk" {
  name                = azurerm_linux_function_app.gha_runner_receiver_function_app.name
  resource_group_name = azurerm_resource_group.gha_runner_rg.name

  depends_on = [ azurerm_linux_function_app.gha_runner_receiver_function_app ]
}
