data "azurerm_resource_group" "rg" {
  name     = var.rg_name #"rg-vnet-001"
}

# Create a new Datadog - Microsoft Azure integration
resource "datadog_integration_azure" "datadog_monitor_integration" {
  tenant_name              = var.azure_tenant_name
  client_id                = var.azure_client_id
  client_secret            = var.azure_client_secret_key
  host_filters             = "examplefilter:true,example:true"
  app_service_plan_filters = "examplefilter:true,example:another"
  container_app_filters    = "examplefilter:true,example:one_more"
  automute                 = true
  cspm_enabled             = true
  custom_metrics_enabled   = false
}

resource "azurerm_datadog_monitor" "datadog_monitor" {
  name                = "example-monitor"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  datadog_organization {
    api_key         = "XXXX"
    application_key = "XXXX"
  }
  user {
    name  = "Example"
    email = "abc@xyz.com"
  }
  sku_name = "Linked"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_datadog_monitor_sso_configuration" "example" {
  datadog_monitor_id        = azurerm_datadog_monitor.datadog_monitor.id
  single_sign_on            = "Enable"
  enterprise_application_id = "${var.enterprise_application_id}" # -> ID'S OF Enterprise_Application_Id
}

resource "azurerm_datadog_monitor_tag_rule" "data_dog_monitor_tag" {
  datadog_monitor_id = azurerm_datadog_monitor.datadog_monitor.id
  log {
    subscription_log_enabled = true
  }
  metric {
    filter {
      name   = "Test"
      value  = "Logs"
      action = "Include"
    }
  }
}