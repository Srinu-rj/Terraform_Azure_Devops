data "azurerm_resource_group" "aks_rg" {
  name = "aks-rg"
}
data "azurerm_virtual_network" "aks_vnet" {
  name                = "aks_vnet"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}
data "azurerm_subnet" "private-aks-subnet" {
  name                 = "aks_private_subnet"
  resource_group_name  = data.azurerm_resource_group.aks_rg.name
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
}
data "azurerm_subnet" "public-aks-subnet" {
  name                 = "aks_public_subnet"
  resource_group_name  = data.azurerm_resource_group.aks_rg.name
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
}

#TODO OUTPUTS
output "aks_vnet" {
  value = data.azurerm_virtual_network.aks_vnet.address_space
}
output "azure_private_subnet" {
  value = data.azurerm_subnet.private-aks-subnet.address_prefixes
}

resource "azurerm_mssql_server" "mysql_server" {
  location                     = data.azurerm_resource_group.aks_rg.location
  name                         = var.mysql_server_name
  resource_group_name          = data.azurerm_resource_group.aks_rg.name
  version                      = "12.0"
  administrator_login          = ""
  administrator_login_password = ""
  minimum_tls_version          = ""
}

resource "azurerm_mssql_database" "mysql_database" {
  name        = var.database_name
  server_id   = azurerm_mssql_server.mysql_server.id
  collation   = var.collection #TODO
  sku_name    = ""             #TODO
  max_size_gb = 20             #TODO
}

resource "azurerm_mssql_firewall_rule" "mysql_firewall" {
  name             = "allow-azure-service"
  server_id        = azurerm_mssql_server.mysql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_virtual_network_rule" "network_rule_for_mysql" {
  count     = length(data.azurerm_subnet.private-aks-subnet.service_endpoints) > 0 ? 1 : 0

  name      = "network_rule_name"
  server_id = azurerm_mssql_server.mysql_server.id
  subnet_id = data.azurerm_subnet.private-aks-subnet.id
}
