
resource "random_string" "function_random" {
  length  = 9
  upper   = false
  special = true

}
resource "azurerm_resource_group" "function_rg_serverless" {
  name     = var.function_rg_name
  location = var.function_rg_location
}

data "azurerm_resource_group" "function_rg" {
  name = "aks-rg" # Pickup a existing resources group.
}

resource "azurerm_storage_account" "function_storage" {
  name                     = "linuxfunctionappsa"
  resource_group_name      = azurerm_resource_group.function_rg_serverless.name
  location                 = azurerm_resource_group.function_rg_serverless.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "function_service_plan" {
  name                = "example-app-service-plan"
  resource_group_name = azurerm_resource_group.function_rg_serverless.name
  location            = azurerm_resource_group.function_rg_serverless.location
  os_type             = var.os_type   #-> "Linux"
  sku_name            = var.sku_name  #-> "B1"
}

resource "azurerm_linux_function_app" "serverless_function_app" {
  name                = var.function_app_name
  resource_group_name = azurerm_resource_group.function_rg_serverless.name
  location            = azurerm_resource_group.function_rg_serverless.location

  storage_account_name = azurerm_storage_account.function_storage.name
  service_plan_id      = azurerm_service_plan.function_service_plan.id

  site_config {}
}

resource "azurerm_linux_function_app_slot" "example" {
  name                 = var.function_app_slot_name
  function_app_id      = azurerm_linux_function_app.serverless_function_app.id
  storage_account_name = azurerm_storage_account.function_storage.name

  site_config {}
}
