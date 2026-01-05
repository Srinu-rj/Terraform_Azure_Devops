#TODO Subscription ID is required for AGIC
data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "aks_rg" {
  name = "aks_rg"
}
data "azurerm_virtual_network" "aks_vnet" {
  name                = "aks_vnet"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}
data "azurerm_subnet" "aks_private_subnet" {
  name                 = "aks_private_subnet"
  resource_group_name  = data.azurerm_resource_group.aks_rg.name
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
}

# locals {
#   apigateway_name                = var.api_gateway_public_ip
#   public_allocation              = var.allocation_method
#   application_gatway             = var.application_gateway_name
#   frontend_port_name             = var.frontend_port_name
#   frontend_ip_configuration_name = var.frontend_ip_configuration_name
#   backend_address_pool_name      = var.backend_address_pool_name
#   http_backend_name              = var.http_backend_name
#   request_routing_rule_name      = var.request_routing_rule_name
#   http_listener_name             = var.http_listener_name
#   routeing_listener_name         = var.routeing_listener_name
#   backend_http_settings_name     = var.backend_http_settings_name
# }


#TODO Public IP
resource "azurerm_public_ip" "api_gate_way_public_ip" {
  name                = var.apigateway_name
  resource_group_name = data.azurerm_resource_group
  location            = data.azurerm_resource_group.aks_rg.location
  allocation_method   = local.public_allocation #TODO STATIC OR DYNAMIC
}
#TODO Application gateway
resource "azurerm_application_gateway" "aks_application_gateway" {
  location            = data.azurerm_resource_group.aks_rg.location
  name                = local.application_gatway
  resource_group_name = data.azurerm_resource_group.aks_rg.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = data.azurerm_subnet.aks_private_subnet.id
  }
  frontend_port {
    name = local.frontend_port_name
    port = 80
  }
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.api_gate_way_public_ip.id
  }
  backend_address_pool {
    name = local.backend_address_pool_name
  }
  backend_http_settings {
    name                  = local.http_backend_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }
  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.routeing_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
  }

}
