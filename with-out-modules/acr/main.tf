data "azurerm_resource_group" "rg" {
  name = "rg-aks-test-001"
}
data "azurerm_virtual_network" "spoke" {
  name                = "vnet-aks-test-001"
  resource_group_name = data.azurerm_resource_group.rg.name
}
data "azurerm_subnet" "private_subnet" {
  name                 =
  resource_group_name  = ""
  virtual_network_name = ""
}

# TODO 🔍 Step 2: Create a Private ACR
resource "azurerm_container_registry" "acr" {
  name                = "acrprivdemo123"   # must be globally unique
  resource_group_name = data.azurerm_resource_group.rg.id
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Premium"          # Premium supports Private Link
  admin_enabled       = false              # disable admin for security
}

#TODO 🔍 Step 3: Attach ACR to AKS (so nodes can pull images)
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

#TODO  🔍 Step 4: Secure ACR with Private Endpoint
resource "azurerm_private_endpoint" "acr_pe" {
  name                = "acr-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "acr-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}

#TODO  🔍 Step 5: Private DNS Zone for ACR
resource "azurerm_private_dns_zone" "acr_dns" {
name                = "privatelink.azurecr.io"
resource_group_name = data.azurerm_resource_group.rg.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_link" {
name                  = "acr-dns-link"
resource_group_name   = data.azurerm_resource_group.rg.id
private_dns_zone_name = azurerm_private_dns_zone.acr_dns.name
virtual_network_id    = data.azurerm_virtual_network.spoke.id
}



#TODO  🔍 Step 6: Push Images
# az acr login --name acrprivdemo123
# docker build -t acrprivdemo123.azurecr.io/spring-food-app:1.0 .
# docker push acrprivdemo123.azurecr.io/spring-food-app:1.0
