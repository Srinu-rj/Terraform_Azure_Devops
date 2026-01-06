resource "azurerm_resource_group" "api_management_rg" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_api_management" "api_management" {
  name                = var.api_management_name
  location            = azurerm_resource_group.api_management_rg.location
  resource_group_name = azurerm_resource_group.api_management_rg.name
  publisher_name      = var.publish_name #"My Company"
  publisher_email     = var.publisher_mail #"company@terraform.io"
  sku_name            = "Developer_1" #Developer_1 or Premium_S1
  http2_enabled      = true
  client_certificate_enabled = true
  virtual_network_type = ""
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_notification_recipient_email" "api_management_notification_mail" {
  api_management_id = azurerm_api_management.api_management.id
  notification_type = "AccountClosedPublisher"
  email             = "dnsrinu143@gmail.com"
}
