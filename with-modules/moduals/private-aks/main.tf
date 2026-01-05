# #TODO Vnet Ids
# data "azurerm_resource_group" "aks_rg" {
#   name = "aks-rg"
# }
data "azurerm_virtual_network" "aks_vnet" {
  name                = "aks_vnet"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}
data "azurerm_virtual_network" "acr_vnet" {
  name                = "acr_vnet"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}
data "azurerm_virtual_network" "agent_vnet" {
  name                = "agent_vnet"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}
data "azurerm_container_registry" "acr_container" {
  name                = "spring" #ACR NAME
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}
data "azurerm_subnet" "aks_subnet" {
  name                 = "private_aks_subnet"
  resource_group_name  = data.azurerm_resource_group.aks_rg.name
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
}
data "azurerm_subnet" "private_aks_subnet" {
  name = "aks_public_subnet"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
}
#TODO PRIVATE DNS
resource "azurerm_private_dns_zone" "private_dns_for_aks" {
  name                = "privatelink.centralindia.azmk8s.io"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "aks_private_dns_network_link"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_for_aks.name
  resource_group_name   = data.azurerm_resource_group.aks_rg.name
  virtual_network_id    = data.azurerm_virtual_network.aks_vnet.id
}
resource "azurerm_private_dns_zone_virtual_network_link" "aks_acr" {
  name                  = "aks_acr_private_dns_link"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_for_aks.name
  resource_group_name   = data.azurerm_resource_group.aks_rg.name
  virtual_network_id    = data.azurerm_virtual_network.acr_vnet.id
}
resource "azurerm_private_dns_zone_virtual_network_link" "aks_agent" {
  name                  = "aks_agent_private_dns_link"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_for_aks.name
  resource_group_name   = data.azurerm_resource_group.aks_rg.name
  virtual_network_id    = data.azurerm_virtual_network.agent_vnet.id
}


#TODO Identity
resource "azurerm_user_assigned_identity" "aks_user_identity" {
  name                = var.aks_user_identity
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}

#TODO Identity role assignment
resource "azurerm_role_assignment" "dns_contributor" {
  principal_id         = azurerm_user_assigned_identity.aks_user_identity.id
  role_definition_name = "Private DNS Zone Contributor"
  scope                = azurerm_private_dns_zone.private_dns_for_aks.id
}
resource "azurerm_role_assignment" "private_dns_contributor" {
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_user_identity.id
  scope                = azurerm_private_dns_zone.private_dns_for_aks.id
}
resource "azurerm_role_assignment" "aks_acr_pull_role" {
  role_definition_name = "AcrPull"
  principal_id         = azurerm_private_dns_zone.private_dns_for_aks.id
  scope                = data.azurerm_container_registry.acr_container.id
}
resource "azurerm_role_assignment" "vnet_subnet_contributor" {
  role_definition_name = "aks_role_assignment"
  principal_id         = azurerm_private_dns_zone.private_dns_for_aks.id
  scope                = data.azurerm_virtual_network.aks_vnet.id
}


resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg
  dns_prefix          = "exampleaks1"   # ✅ put here

  default_node_pool {
    name           = var.default_node_pool_name #default
    vm_size        = var.default_node_pool_vm_name
    vnet_subnet_id = data.azurerm_subnet.aks_subnet.id #TODO AKS SUBNET
    # zones          = []
    node_count = 1
    enable_auto_scaling = false   # ✅ correct argument name
    max_pods       = var.default_max_pods
    max_count      = var.default_max_node_count
    min_count      = var.default_min_node_count
    os_disk_type   = var.default_disk_type
    os_disk_size_gb = 30


    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "dev"
      "nodepoolos"    = "linux"
      "app"           = "system-apps"
    }
  }

  linux_profile {
    admin_username = var.admin_user
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # ingress_application_gateway {}
  # azure_active_directory_role_based_access_control {}

  network_profile {
    network_plugin    = var.network_network_plugin
    dns_service_ip    = var.network_dns_service_ip
    service_cidr      = var.network_service_cidr
    # network_plugin = "Calico"   # Required for Calico
    network_policy = "calico"  # ✅ Enables Calico
    load_balancer_sku = "standard"
  }
  # Enable Azure Policy and monitoring
  azure_policy_enabled             = true

  depends_on = [
    azurerm_role_assignment.dns_contributor
  ]
}
