variable "service_bus_rg" { type = string }
variable "service_bus_location" { type = string }

variable "primary_service_bus_namespace_name" { type = string }
variable "primary_bus_sku_namespace" { type = string }

variable "secondary_service_bus_namespace_name" { type = string }
variable "secondary_bus_sku_namespace" { type = string }

variable "bus_ns_rule_name" { type = string }

variable "disaster_namespace_recover_config_name" { type = string }
variable "service_bus_queue_name" { type = string }
variable "service_bus_topic_name" { type = string }
variable "service_bus_subscription_name" { type = string }

variable "service_bus_log_analytics_name" { type = string }
variable "service_bus_application_insights_name" { type = string }
