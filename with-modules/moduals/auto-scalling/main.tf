data "azurerm_resource_group" "aks_rg" {
  name = "aks_rg"
}
data "azurerm_virtual_network" "aks_vnet" {
  name                = "aks_vnet"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}

resource "random_password" "random_pass" {
  length = 8
  special = true
  upper = true
  numeric = true
}


resource "azurerm_public_ip" "load_balancer_public_ip" {
  name                = "PublicIPForLB"
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  allocation_method   = "Static"
}
resource "azurerm_lb" "azure_load_balancer" {
  name                = "azure_load_balancer"
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  sku = "Standard"
  frontend_ip_configuration {
    name = "PublicIPAddress",
    public_ip_address_id = azurerm_public_ip.load_balancer_public_ip.id
  }
  depends_on = [
    azurerm_public_ip.load_balancer_public_ip
  ]
}

resource "azurerm_lb_rule" "azure_lb_rule" {
  backend_port                   = 1133 #TODO Back-End application port number
  frontend_ip_configuration_name = azurerm_lb.azure_load_balancer.frontend_ip_configuration.name #"PublicIPAddress"
  frontend_port                  = 8080 #TODO Fronted-end application port number
  loadbalancer_id                = azurerm_lb.azure_load_balancer.id
  name                           = "azure_load_balancer_rule"
  protocol                       = "Tcp"
}