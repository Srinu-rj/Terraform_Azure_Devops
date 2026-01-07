terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}
resource "azurerm_resource_group" "vpn_rg" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_virtual_wan" "wan_vpn" {
  name                = "example-vwan"
  resource_group_name = azurerm_resource_group.vpn_rg.name
  location            = azurerm_resource_group.vpn_rg.location
}

resource "azurerm_virtual_network" "vpn_vnet" {
  name                = "example-network"
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_virtual_hub" "virtual_hub" {
  location            = azurerm_resource_group.vpn_rg.location
  name                = var.virtual_hub_name
  resource_group_name = azurerm_resource_group.vpn_rg.name
  virtual_wan_id = azurerm_virtual_wan.wan_vpn.id
  address_prefix = ""
}
resource "azurerm_vpn_gateway" "vpn_gateway" {
  name                = var.vpn_gateway_name
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
  virtual_hub_id      = azurerm_virtual_hub.virtual_hub.id
}
# TODO -> azurerm_vpn_site resource represents a physical or logical on-premises location that needs to be connected to an Azure virtual network.
#         It holds configuration details such as the public IP address of the on-premises VPN device, the address space of the local network, and the connection settings required for establishing a Site-to-Site VPN.
#         The azurerm_vpn_site is typically used in conjunction with azurerm_vpn_gateway_connection to define the remote endpoint of the connection.
resource "azurerm_vpn_site" "vpn_site" {
  name                = "example-vpn-site"
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
  virtual_wan_id      = azurerm_virtual_wan.wan_vpn.id
  link {
    name       = "link1"
    ip_address = "10.1.0.0"
  }
  link {
    name       = "link2"
    ip_address = "10.2.0.0"
  }
}

# TODO -> azurerm_vpn_gateway_connection resource in Terraform is used to establish a secure, encrypted connection between a virtual network gateway in Azure and either a local network gateway (representing an on-premises network) or another Azure VPN site.
#         It supports various connection types, including Site-to-Site (S2S), VNet-to-VNet, and Point-to-Site (P2S) connections, and is essential for enabling cross-premises or inter-VNet communication over the public internet using IPsec/IKE protocols.

resource "azurerm_vpn_gateway_connection" "vpn_gateway_connection" {
  name               = var.vpn_gateway_connection_name
  remote_vpn_site_id = azurerm_vpn_site.vpn_site.id
  vpn_gateway_id     = azurerm_vpn_gateway.vpn_gateway.id

  vpn_link {
    name             = "link1"
    vpn_site_link_id = azurerm_vpn_site.vpn_site.link[0].id
  }

  vpn_link {
    name             = "link2"
    vpn_site_link_id = azurerm_vpn_site.vpn_site.link[1].id
  }
}

resource "azurerm_vpn_gateway_nat_rule" "vpn_gateway_nat_rule" {
  name           = var.vpn_gateway_nat_rule_name
  vpn_gateway_id = azurerm_vpn_gateway.vpn_gateway.id

  external_mapping {
    address_space = "192.168.21.0/26"
  }

  internal_mapping {
    address_space = "10.4.0.0/26"
  }
}