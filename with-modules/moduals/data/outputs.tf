data "azurerm_resource_group" "aks" {
  name = "aks-rg"
}

data "azurerm_virtual_network" "acr_vnet" {
  name                = "acr_vnet"
  resource_group_name = data.azurerm_resource_group.aks.name
}
data "azurerm_virtual_network" "aks_vnet" {
  name                = "aks_vnet"
  resource_group_name = data.azurerm_resource_group.aks.name
}
data "azurerm_virtual_network" "agent_vnet" {
  name                = "agent_vnet"
  resource_group_name = data.azurerm_resource_group.aks.name
}
data "azurerm_subnet" "acr_private_subnet" {
  name                 = "acr_private_subnet"
  resource_group_name  = data.azurerm_resource_group.aks.name
  virtual_network_name = data.azurerm_virtual_network.acr_vnet.name
}

#==================================================================
# data "azurerm_resource_group" "aks" {
#   name = "aks-rg"
# }
# data "azurerm_subnet" "private_acr" {
#   name                 = "acr_private_subnet"
#   resource_group_name  = data.azurerm_resource_group.aks_rg.name
#   virtual_network_name = data.azurerm_virtual_machine.acr_vnet.name
# }
# data "azurerm_virtual_machine" "aks_vnet" {
#   name                = "aks_vnet"
#   resource_group_name = data.azurerm_resource_group.aks_rg.name
# }
# data "azurerm_virtual_machine" "acr_vnet" {
#   name                = "acr_vnet"
#   resource_group_name = data.azurerm_resource_group.aks_rg.name
# }
# data "azurerm_virtual_machine" "agent_vnet" {
#   name                = "agent_vnet"
#   resource_group_name = data.azurerm_resource_group.aks_rg.name
# }
