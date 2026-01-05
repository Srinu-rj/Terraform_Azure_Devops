resource "azurerm_resource_group" "app_services_rg" {
  location = var.location
  name     = var.name
}

resource "azurerm_virtual_network" "app_service_vnet" {
  name                = var.app_services_vnet
  location            = azurerm_resource_group.app_services_rg.location
  resource_group_name = azurerm_resource_group.app_services_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "app_subnet" {
  name                 = var.app_subnet_01
  resource_group_name  = azurerm_resource_group.app_services_rg.name
  virtual_network_name = azurerm_virtual_network.app_service_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "Microsoft.Web/hostingEnvironments"
    service_delegation {
      name    = "Microsoft.Web/hostingEnvironments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  depends_on = [azurerm_virtual_network.app_service_vnet,
  ]
}

resource "azurerm_route_table" "route_table" {
  name                = var.route_table_name
  location            = azurerm_resource_group.app_services_rg.location
  resource_group_name = azurerm_resource_group.app_services_rg.name
  route {
    name                   = "route1"
    address_prefix         = "10.0.1.0/24" #should must match with subnet CIDR
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.1.1"
  }
}

resource "azurerm_subnet_route_table_association" "sub_route_association" {
  route_table_id = azurerm_route_table.route_table.id
  subnet_id      = azurerm_subnet.app_subnet.id
}
