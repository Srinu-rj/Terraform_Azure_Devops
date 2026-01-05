resource "azurerm_resource_group" "aks_rg" {
  name     = var.aks_rg_name
  location = var.location
}

#TODO AKS vnet and subnets
resource "azurerm_virtual_network" "aks_vnet" {
  location            = azurerm_resource_group.aks_rg.location
  name                = var.aks_vnet_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  address_space       = var.aks_vnet_cidr
}
resource "azurerm_subnet" "aks_public_subnet" {
  name                 = var.aks_public_subnet_name
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = var.aks_public_subnet_cidr
}
resource "azurerm_subnet" "aks_private_subnet" {
  name                 = var.aks_private_subnet_name
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name

}  address_prefixes     = var.aks_private_subnet_cidr
# TODO Microsoft.Storage, Microsoft.KeyVault
service_endpoints = ["Microsoft.Sql"]

#TODO ACR vnet and subnet
resource "azurerm_virtual_network" "acr_vnet" {
  location            = azurerm_resource_group.aks_rg.location
  name                = var.acr_vnet_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  address_space       = var.acr_vnet_cidr
}
resource "azurerm_subnet" "acr_private_subnet" {
  name                 = var.acr_private_subnet_name
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.acr_vnet.name
  address_prefixes     = var.acr_private_subnet_cidr
  service_endpoints    = ["Microsoft.ContainerRegistry"]
}

#TODO agent vnet and subnet
resource "azurerm_virtual_network" "agent_vnet" {
  name                = var.agent_vnet_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  address_space       = var.agent_vnet_cidr
}
resource "azurerm_subnet" "agent_subnet" {
  name                 = var.agent_subnet_name
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.agent_vnet.name
  address_prefixes     = var.agent_subnet_cidr
}

#TODO VNet Peering between AKS VNet, ACR VNet and Agent VNet
resource "azurerm_virtual_network_peering" "aks_to_acr" {
  name                         = "aks-to-acr"
  remote_virtual_network_id    = azurerm_virtual_network.acr_vnet.id
  resource_group_name          = azurerm_resource_group.aks_rg.name
  virtual_network_name         = azurerm_virtual_network.aks_vnet.name
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true
}
resource "azurerm_virtual_network_peering" "acr_to_aks" {
  name                         = "aks-to-acr"
  remote_virtual_network_id    = azurerm_virtual_network.aks_vnet.id
  resource_group_name          = azurerm_resource_group.aks_rg.name
  virtual_network_name         = azurerm_virtual_network.acr_vnet.name
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true
}
resource "azurerm_virtual_network_peering" "aks_to_agent" {
  name                         = "aks_to_agent"
  remote_virtual_network_id    = azurerm_virtual_network.agent_vnet.id
  resource_group_name          = azurerm_resource_group.aks_rg.name
  virtual_network_name         = azurerm_virtual_network.aks_vnet.name
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true
}
resource "azurerm_virtual_network_peering" "agent_to_aks" {
  name                         = "agent_to_aks"
  remote_virtual_network_id    = azurerm_virtual_network.aks_vnet.id
  resource_group_name          = azurerm_resource_group.aks_rg.name
  virtual_network_name         = azurerm_virtual_network.agent_vnet.name
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true
}
resource "azurerm_virtual_network_peering" "acr_to_agent" {
  name                         = "acr_to_agent"
  remote_virtual_network_id    = azurerm_virtual_network.agent_vnet.id
  resource_group_name          = azurerm_resource_group.aks_rg.name
  virtual_network_name         = azurerm_virtual_network.acr_vnet.name
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true
}
resource "azurerm_virtual_network_peering" "agent_to_acr" {
  name                         = "agent_to_acr"
  remote_virtual_network_id    = azurerm_virtual_network.acr_vnet.id
  resource_group_name          = azurerm_resource_group.aks_rg.name
  virtual_network_name         = azurerm_virtual_network.agent_vnet.name
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  allow_virtual_network_access = true
}

resource "azurerm_public_ip" "pub_ip" {
  name                = "firewall_public_ip"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# firewall -> application rule collection -> nat_rule_collection -> network_rule_collection
# firewall -> firewall_policy [firewall_policy_rule_collection_group]
resource "azurerm_firewall" "vnet_firewall" {
  name                = "azure_firewall"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku_name            = "firewall_sku"
  sku_tier            = "Standard"

  ip_configuration {
    name = "pub_ip_config_firewall"
    subnet_id = ""
    public_ip_address_id = azurerm_public_ip.pub_ip.id
  }
}

resource "azurerm_firewall_application_rule_collection" "firewall_application_rules" {
  action              = ""
  azure_firewall_name = azure
  name                = ""
  priority            = 100
  resource_group_name = azurerm_resource_group.aks_rg.name

  rule {
    name             = "application_firewall_rules"
    source_addresses = [] # single IP -> "10.0.0.0/16",
    source_ip_groups = [] #numbers of groups
    fqdn_tags        = [] # domain name -> "*.google.com",

    protocol {
      port = "443"
      type = "Https"
    }
  }
}


# resource "azurerm_subnet" "acr_public_subnet" {
#   name                 = var.acr_public_subnet_name
#   resource_group_name  = azurerm_resource_group.aks_rg.name
#   virtual_network_name = azurerm_virtual_network.acr_vnet.name
#   address_prefixes = var.acr_public_subnet_cird
# }
#
# resource "azurerm_subnet" "acr_private_subnet" {
#   name                 = var.acr_private_subnet_name
#   resource_group_name  = azurerm_resource_group.aks_rg.name
#   virtual_network_name = azurerm_virtual_network.acr_vnet.name
#   address_prefixes = var.acr_private_subnet_cird
# }

