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

resource "azurerm_container_registry" "private_acr" {
  name                          = var.acr_registry_name
  resource_group_name           = data.azurerm_resource_group.aks.name
  location                      = data.azurerm_resource_group.aks.location
  sku                           = var.acr_sku # TODO Standard, Basic ,Premium.
  admin_enabled                 = false
  public_network_access_enabled = false # ✅ disables public access

  network_rule_set {
    default_action = "Deny"

    ip_rule {
      action   = "Allow"
      ip_range = "13.0.0.0/16"
    }
  }
  georeplications {
    location                = "centralindia"
    zone_redundancy_enabled = true
    tags                    = {}
  }
  georeplications {
    location                = "southeastasia"
    zone_redundancy_enabled = true
    tags                    = {}
  }
}
#TODO LOGIN ACR SERVER
output "acr_login" {
  description = "Login Acr Images"
  value = azurerm_container_registry.private_acr.login_server
}
#TODO Create azure private DNS ZONE TO SECURE LOGIN
resource "azurerm_private_dns_zone" "acr_private_dns" {
  name                = "acrconnetion.azurecr.io"
  resource_group_name = data.azurerm_resource_group.aks.name
}

#TODO Create azure private endpoint
resource "azurerm_private_endpoint" "acr_private_endpoint" {
  name                = var.acr_private_endpoint_name
  resource_group_name = data.azurerm_resource_group.aks.name
  location            = data.azurerm_resource_group.aks.location
  subnet_id           = data.azurerm_subnet.acr_private_subnet.id

  private_dns_zone_group {
    name = var.private_dns_zone
    private_dns_zone_ids = [azurerm_private_dns_zone.acr_private_dns.id]
  }
  private_service_connection {
    is_manual_connection = false
    name                 = "${var.acr_registry_name}-private-endpoint"
    private_connection_resource_id = azurerm_container_registry.private_acr.id
    subresource_names = ["registry"]
  }
}

#TODO I HAVE ALREADY CREATED 2 V-NET'S FOR [ ACR TO AKS TO AGENT ]
resource "azurerm_private_dns_zone_virtual_network_link" "acr_vnet_link" {
  name                  = var.acr_vnet_link_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_private_dns.name
  resource_group_name   = data.azurerm_resource_group.aks.name
  virtual_network_id    = data.azurerm_virtual_network.acr_vnet.id #TODO ACR VNET

  depends_on = [azurerm_private_dns_zone.acr_private_dns]
}
resource "azurerm_private_dns_zone_virtual_network_link" "aks_vnet_link" {
  name                  = var.aks_vnet_link_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_private_dns.name
  resource_group_name   = data.azurerm_resource_group.aks.name
  virtual_network_id    = data.azurerm_virtual_network.aks_vnet.id
}
resource "azurerm_private_dns_zone_virtual_network_link" "agent_vnet_link" {
  name                  = var.agent_vnet_link_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_private_dns.name
  resource_group_name   = data.azurerm_resource_group.aks.name
  virtual_network_id    = data.azurerm_virtual_network.agent_vnet.id
}

# #TODO GET THE SERVICE PRINCIPAL ID AND ATTACH TO THE ROLE ASSIGNMENT
# data "azuread_service_principal" "acr-service_principal" {
#   display_name = "" #TODO ACR SERVICE PRINCIPAL NAME
# }
# #TODO Create Virtual network link in private dns zone
# resource "azurerm_role_assignment" "acr_role" {
#   principal_id = data.azuread_service_principal.acr-service_principal.object_id  #TODO HERE WE NEED TO GET PRINCIPIAL OBJECT ID 👍
#   scope        = azurerm_container_registry.private_acr.id  #TODO GET THE ACR ID
#   role_definition_name = "AcrPush" # role iam Permission
# }