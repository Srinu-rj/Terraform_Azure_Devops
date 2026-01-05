variable "cdn_rg_location" { type = string }
variable "cdn_rg_name" { type = string }
variable "cdn_profile_name" { type = string }
variable "cdn_sku" { type = string }
variable "front_door_profile_name" { type = string }
variable "front_door_sku" {}
variable "front_door_endpoint_name" { type = string }
variable "front_door_rule_set" { type = string }
variable "front_door_origin_group_name" {}
variable "front_door_origin_name" { type = string }
variable "static_front_door_rule_name" { type = string }
variable "default_route_name" { type = string }
variable "application_custom_domain_name" { type = string }
variable "application_host_name" { type = string }