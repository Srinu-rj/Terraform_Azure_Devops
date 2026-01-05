
resource "azurerm_resource_group" "redis_cache_rg" {
  name     = var.redis_cache_rg_name
  location = var.redis_cache_location_name
}

resource "random_id" "server" {
  keepers = {
    azi_id = 1
  }

  byte_length = 8
}

resource "azurerm_redis_cache" "primary_back_end_redis_cache" {
  name                = "primary_redis${random_id.server.hex}"
  location            = azurerm_resource_group.redis_cache_rg.location
  resource_group_name = azurerm_resource_group.redis_cache_rg.name
  family              = "C"        #TODO -> C  [ Basic/Standard SKU ]  P [ Premium ]  {Family and sku should be match} like -> [ family= "P" sku_name= "Premium"]
  capacity            = 3          #TODO -> C  [ 0, 1, 2, 3, 4, 5, 6 ]  P [1, 2, 3, 4, 5]
  sku_name            = "Standard" #TODO -> Basic, Standard and Premium.

  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  redis_configuration {
    maxmemory_reserved = 2
    maxmemory_delta    = 2
    maxmemory_policy   = "allkeys-lru"
  }

}
resource "azurerm_redis_cache" "secondary_back_end_redis_cache" {
  name                = "secondary_redis${random_id.server.hex}"
  location            = azurerm_resource_group.redis_cache_rg.location
  resource_group_name = azurerm_resource_group.redis_cache_rg.name
  family              = "P"       #TODO -> C  [ Basic/Standard SKU ]  P [ Premium ]  {Family and sku should be match} like -> [ family= "P" sku_name= "Premium"]
  capacity            = 3         #TODO -> C  [ 0, 1, 2, 3, 4, 5, 6 ]  P [1, 2, 3, 4, 5]
  sku_name            = "Premium" #TODO -> Basic, Standard and Premium.

  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  redis_configuration {
    maxmemory_reserved = 2
    maxmemory_delta    = 2
    maxmemory_policy   = "allkeys-lru"
  }
}

resource "azurerm_redis_cache_access_policy" "redis_cache_policy" {
  name           = var.redis_cache_policy_name
  redis_cache_id = azurerm_redis_cache.primary_back_end_redis_cache.id
  permissions    = "+@read +@connection +cluster|info"
}

data "azurerm_client_config" "my_subscription_client" {}

resource "azurerm_redis_cache_access_policy_assignment" "redis_cache_policy_assignment" {
  name               = var.redis_cache_policy_assignment_name
  redis_cache_id     = azurerm_redis_cache.primary_back_end_redis_cache.id
  access_policy_name = "Data Contributor"
  object_id          = data.azurerm_client_config.my_subscription_client.object_id
  object_id_alias    = "ServicePrincipal" #TODO -> im not sure
}

resource "azurerm_redis_firewall_rule" "redis_firewall" {
  name                = var.redis_firewall_name
  redis_cache_name    = azurerm_redis_cache.primary_back_end_redis_cache.name
  resource_group_name = azurerm_resource_group.redis_cache_rg.name
  start_ip            = "1.2.3.4"
  end_ip              = "2.3.4.5"
}
#TODO -> Primary redis cache to secondary.
resource "azurerm_redis_linked_server" "redis_linked_server" {
  linked_redis_cache_id       = azurerm_redis_cache.secondary_back_end_redis_cache.id
  linked_redis_cache_location = azurerm_redis_cache.primary_back_end_redis_cache.location #TODO im not sure plz check
  resource_group_name         = azurerm_resource_group.redis_cache_rg.name
  target_redis_cache_name     = azurerm_redis_cache.primary_back_end_redis_cache.name
  server_role                 = "Secondary"
}
