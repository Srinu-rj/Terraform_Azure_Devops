resource "random_id" "random_server" {
  keepers = {
    azi_id = 1
  }
  byte_length = 8
}

resource "azurerm_resource_group" "traffic_rg" {
  name     = "trafficmanagerProfile"
  location = "West Europe"
}
resource "azurerm_public_ip" "traffic_manager_public_ip" {
  name                = "traffic_manager_pub_ip"
  location            = azurerm_resource_group.traffic_rg.location
  resource_group_name = azurerm_resource_group.traffic_rg.name
  allocation_method   = "Static"
  domain_name_label   = "example-public-ip"
}

#TODO -> Allowing HTTP
resource "azurerm_traffic_manager_profile" "parent_traffic_manager_profile" {
  name                   = random_id.random_server.hex
  resource_group_name    = azurerm_resource_group.traffic_rg.name
  traffic_routing_method = "Weighted"
  dns_config {
    relative_name = random_id.random_server.hex
    ttl           = 100
  }
  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
  tags = {
    environment = "Production"
  }
}

#TODO -> Allowing HTTPS.
resource "azurerm_traffic_manager_profile" "nested_traffic_manager_profile" {
  name                   = random_id.random_server.hex
  resource_group_name    = azurerm_resource_group.traffic_rg.name
  traffic_routing_method = "Weighted"
  dns_config {
    relative_name = "nested-profile"
    ttl           = 30
  }
  monitor_config {

    protocol                     = "HTTP"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 2
  }
}

#TODO -> Communicate Traffic Manager Parent profile to Traffic Manager Nested Profile:
resource "azurerm_traffic_manager_nested_endpoint" "parent_to_nested" {
  minimum_child_endpoints = 9
  name                    = "endpoint_traffic_manager"
  priority                = 1
  profile_id              = azurerm_traffic_manager_profile.parent_traffic_manager_profile.id
  target_resource_id      = azurerm_traffic_manager_profile.nested_traffic_manager_profile.id
  weight                  = 5
}

# TODO -> Communicate Public IP Drought the traffic to the Parent Traffic Manager profile.
resource "azurerm_traffic_manager_azure_endpoint" "public_traffic_ip_endpoint" {
  name               = "traffic_manager_public_endpoint"
  profile_id         = azurerm_traffic_manager_profile.parent_traffic_manager_profile.id
  target_resource_id = azurerm_public_ip.traffic_manager_public_ip.id
}

#TODO -> Creating Azure Traffic Manager Domain [IP]->[DNS] [Route the traffic TO  Azure Traffic Manager Domain ]
resource "azurerm_traffic_manager_external_endpoint" "external_domain" {
  name                 = "example-endpoint"
  profile_id           = azurerm_traffic_manager_profile.parent_traffic_manager_profile.id
  always_serve_enabled = true
  weight               = 100
  target               = "www.srinu10.com"
}
