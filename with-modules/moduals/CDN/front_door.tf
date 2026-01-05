locals {
  cdn_rg_location  = var.cdn_rg_location
  cdn_rg_name      = var.cdn_rg_name
  cdn_profile_name = var.cdn_profile_name
  cdn_sku          = var.cdn_sku
  front_door_profile_name =var.front_door_profile_name
  front_door_sku=var.front_door_sku
  front_door_endpoint_name=var.front_door_endpoint_name
  front_door_rule_set = var.front_door_rule_set
  front_door_origin_group_name=var.front_door_origin_group_name
  front_door_frontdoor_origin_name= var.front_door_origin_name
  static_front_door_rule_name=var.static_front_door_rule_name
  deafult_route_name=var.default_route_name
  application_custom_domain_name=var.application_custom_domain_name
  application_host_name=var.application_host_name
}

resource "azurerm_resource_group" "cdn_rg" {
  location = local.cdn_rg_location
  name     = local.cdn_rg_name
}

# --> TODO there are two types of CDN 1: -> CDN (classic)  2: -> CDN frontdoor
# cdn_front_door_profile
resource "azurerm_cdn_frontdoor_profile" "cdn_front_door_profile" {
  name                     = local.front_door_profile_name
  resource_group_name      = azurerm_resource_group.cdn_rg.name
  response_timeout_seconds = 20
  sku_name                 = local.front_door_sku
}
# cdn_front_door_endpoint
resource "azurerm_cdn_frontdoor_endpoint" "cdn_front_door_endpoint_name" {
  name                     = local.front_door_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn_front_door_profile.id
}
# front_door_ruleset
resource "azurerm_cdn_frontdoor_rule_set" "cdn_front_door_rule_set" {
  name                     = local.front_door_rule_set
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn_front_door_profile.id
}
# origin group
resource "azurerm_cdn_frontdoor_origin_group" "cdn_front_door_origin_group" {
  name                     = local.front_door_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn_front_door_profile.id

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 10
    successful_samples_required        = 3
  }

  health_probe {
    interval_in_seconds = 100
    protocol            = "HTTP"
    path                = "/index.html" # ["/index.html", "js", "ts","tsx","jsx"]
    request_type        = "HEAD"
  }
}
resource "azurerm_cdn_frontdoor_origin" "cdn_front_door_origin" {
  depends_on = [azurerm_storage_account.cdn_storage_account.id] #static web storage
  name                           = local.front_door_frontdoor_origin_name
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.cdn_front_door_origin_group.id
  certificate_name_check_enabled = false
  enabled                        = true
  host_name                      = azurerm_storage_account.cdn_storage_account.id #storage account name
  origin_host_header             = azurerm_storage_account.cdn_storage_account.id #storage account name

  http_port  = 80
  https_port = 443
  priority   = 1
  weight     = 1000
}

resource "azurerm_cdn_frontdoor_rule" "cdn_cache_rule" {
  depends_on = [
    azurerm_cdn_frontdoor_origin.cdn_front_door_origin.id,
    azurerm_cdn_frontdoor_origin_group.cdn_front_door_origin_group.id

  ]
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.cdn_front_door_rule_set.id
  name                      = local.static_front_door_rule_name #static
  order                     = 1
  behavior_on_match = "Stop"

  conditions {
    url_file_extension_condition {
      match_values = ["css","html","js","jsx","ts","jpg","png","jpeg",".map","ico"]
      operator = "Equal"
    }
  }
  actions {
    route_configuration_override_action {
      compression_enabled = true,
      cache_behavior = "HonarOrigin"
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "default_route" {
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.cdn_front_door_endpoint_name.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.cdn_front_door_origin_group.id
  name                          = local.deafult_route_name
  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.cdn_front_door_origin.id]
  cdn_frontdoor_rule_set_ids = [azurerm_cdn_frontdoor_rule_set.cdn_front_door_rule_set.id]


  enabled = true
  forwarding_protocol = "MatchRequest"
  https_redirect_enabled = true
  link_to_default_domain = false
  patterns_to_match = ["/*"]
  supported_protocols = ["Http","Https"]
}

resource "azurerm_cdn_frontdoor_custom_domain" "application_custom_domain" {
  name                     = local.application_custom_domain_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn_front_door_profile.id
  host_name                = local.application_host_name # www.ihelpterraform.com -> custom domain

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}
resource "azurerm_cdn_frontdoor_custom_domain_association" "custom_domain_association" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.application_custom_domain.id
  cdn_frontdoor_route_ids = [azurerm_cdn_frontdoor_route.default_route.id]
}