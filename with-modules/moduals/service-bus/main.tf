#TODO -> Azure Service Bus is a fully managed enterprise message broker that enables reliable communication between applications and services using queues and topics.
# Its main components are namespaces, queues, topics, subscriptions, and access policies.
# In Terraform, you can improve deployments by modularizing resources,
# using variable groups, securing secrets with Key Vault, and automating scaling and monitoring.

# TODO -> SERVICE BUS:
# TODO -> create service bus namespace -> shared access policies -> create a entity like Queues and Topic -> servicebus_queue -> servicebus_topic -> subscriptions[notification]
resource "azurerm_resource_group" "service_bus_rg" {
  name     = var.service_bus_rg
  location = var.service_bus_location
}

#TODO -> A container for Service Bus resources (queues, topics, subscriptions). Acts as a logical boundary. [ primary ]
resource "azurerm_servicebus_namespace" "primary_service_bus_namespace" {
  name                = var.primary_service_bus_namespace_name
  location            = azurerm_resource_group.service_bus_rg.location
  resource_group_name = azurerm_resource_group.service_bus_rg.name
  sku                 = var.primary_bus_sku_namespace #"Standard"
}

#TODO -> A container for Service Bus resources (queues, topics, subscriptions). Acts as a logical boundary. [ secondary ]
resource "azurerm_servicebus_namespace" "secondary_service_bus_namespace" {
  name                = var.secondary_service_bus_namespace_name
  location            = azurerm_resource_group.service_bus_rg.location
  resource_group_name = azurerm_resource_group.service_bus_rg.name
  sku                 = var.secondary_bus_sku_namespace #"Standard"
}
#TODO -> Primary Authorization Rule for Service Bus Namespace
resource "azurerm_servicebus_namespace_authorization_rule" "primary_service_bus_auth_rule" {
  name         = var.primary_bus_ns_rule_name
  namespace_id = azurerm_servicebus_namespace.primary_service_bus_namespace.id

  listen = true
  send   = true
  manage = true

}
#TODO -> secondary Authorization Rule for Service Bus Namespace
resource "azurerm_servicebus_namespace_authorization_rule" "secondary_service_bus_auth_rule" {
  name         = var.secondary_bus_ns_rule_name
  namespace_id = azurerm_servicebus_namespace.secondary_service_bus_namespace.id

  listen = true
  send   = true
  manage = true
}

# TODO -> Data Source to fetch existing Service Bus Namespace Authorization Rule [DATA AND OUTPUT]
data "azurerm_servicebus_namespace_authorization_rule" "primary_service_bus_auth_rule" {
  name         = azurerm_servicebus_namespace_authorization_rule.primary_service_bus_auth_rule.name
  namespace_id = azurerm_servicebus_namespace.primary_service_bus_namespace.id
}
output "rule_id" {
  value = data.azurerm_servicebus_namespace_authorization_rule.primary_service_bus_auth_rule.id
}

data "azurerm_servicebus_namespace_authorization_rule" "secondary_service_bus_auth_rule" {
  name         = azurerm_servicebus_namespace_authorization_rule.secondary_service_bus_auth_rule.name
  namespace_id = azurerm_servicebus_namespace.secondary_service_bus_namespace.id
}
output "azurerm_servicebus_namespace_authorization_rule"  {
  value = data.azurerm_servicebus_namespace_authorization_rule.secondary_service_bus_auth_rule.id
}



#TODO -> It is not possible to remove the Customer Managed Key from the Service Bus Namespace once it's been added. To remove the Customer Managed Key, the parent Service Bus Namespace must be deleted and recreated.
#TODO -> still not implemented

#TODO -> Disaster Recovery Config is a Premium SKU only capability [ Disaster Recovery Config for a Service Bus Namespace ]
resource "azurerm_servicebus_namespace_disaster_recovery_config" "disaster_namespace_recover_config" {
  name                        = var.disaster_namespace_recover_config_name
  primary_namespace_id        = azurerm_servicebus_namespace.primary_service_bus_namespace.id
  partner_namespace_id        = azurerm_servicebus_namespace.secondary_service_bus_namespace.id
  alias_authorization_rule_id = azurerm_servicebus_namespace_authorization_rule.primary_service_bus_auth_rule.id
}

#TODO -> Stores messages in FIFO order. Used for point-to-point communication.
resource "azurerm_servicebus_queue" "service_bus_queue" {
  name                                    = var.service_bus_queue_name
  namespace_name                          = azurerm_servicebus_namespace.primary_service_bus_namespace.id
  resource_group_name                     = azurerm_resource_group.service_bus_rg.id
  enable_partitioning                     = true
  max_size_in_megabytes                   = 1024
  namespace_id                            = azurerm_servicebus_namespace.primary_service_bus_namespace.id
  auto_delete_on_idle                     = "PT30M"
  status                                  = "Active"
  duplicate_detection_history_time_window = "PT10M"
  batched_operations_enabled              = true
  timeouts {
    create = "30m"
    read   = "30m"
    delete = "30m"
    update = "5m"
  }
}

#TODO -> [Topic] -> Supports publish-subscribe pattern. Messages sent to a topic can be consumed by multiple subscribers.
resource "azurerm_servicebus_topic" "service_bus_topic" {
  name                 = var.service_bus_topic_name
  namespace_id         = azurerm_servicebus_namespace.primary_service_bus_namespace.id
  partitioning_enabled = true
  auto_delete_on_idle                     = "PT30M"
  status                                  = "Active"
  duplicate_detection_history_time_window = "PT10M"
  batched_operations_enabled              = true
  timeouts {
    create = "30m"
    read   = "30m"
    delete = "30m"
    update = "5m"
  }

}

#TODO -> A virtual queue attached to a topic. Each subscription receives a copy of messages.
resource "azurerm_servicebus_subscription" "service_bus_subscription" {
  max_delivery_count = 1
  name               = var.service_bus_subscription_name
  topic_id           = azurerm_servicebus_topic.service_bus_topic.id
}

#TODO -> [ Application Insights ] MONITORING FOR SERVICE BUS
resource "azurerm_log_analytics_workspace" "service_bus_log_analytics" {
  name                = var.service_bus_log_analytics_name
  location            = azurerm_resource_group.service_bus_rg.location
  resource_group_name = azurerm_resource_group.service_bus_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "service_bus_application_insights" {
  name                = var.service_bus_application_insights_name
  location            = azurerm_resource_group.service_bus_rg.location
  resource_group_name = azurerm_resource_group.service_bus_rg.name
  workspace_id        = azurerm_log_analytics_workspace.service_bus_log_analytics.id
  application_type    = "web" # TODO -> APP | WEB
}

output "instrumentation_key" {
  value = azurerm_application_insights.service_bus_application_insights.instrumentation_key
}

output "app_id" {
  value = azurerm_application_insights.service_bus_application_insights.app_id
}
