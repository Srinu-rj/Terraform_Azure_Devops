
locals {
  rg_name                = "" # add your resource group name
  storage_account_name   = "" # add your storage account name
  storage_container_name = "" # add your storage container name
  blob_name              = "" # add your blob name
}

data "azurerm_subscription" "cost_subscription" {}

# TODO -> GET THE VALUES FOR WHAT YOU NEED TO MONITOR COSTS
data "azurerm_resource_group" "cost_management_rg" {
  name = local.rg_name
}
data "azurerm_storage_account" "cost_management_storage_account" {
  name                = local.storage_account_name
  resource_group_name = data.azurerm_resource_group.cost_management_rg.name
}
data "azurerm_storage_container" "cost_management_container" {
  name = local.storage_container_name
}
data "azurerm_storage_blob" "cost_management_blob" {
  name                   = local.blob_name
  storage_account_name   = data.azurerm_storage_account.cost_management_storage_account.name
  storage_container_name = data.azurerm_storage_container.cost_management_container.name
}

resource "azurerm_billing_account_cost_management_export" "billing_account_cost_management" {
  name                         = "billing_account_cost_management_name"
  billing_account_id           = "example"
  recurrence_type              = "Monthly"
  recurrence_period_start_date = "2020-08-18T00:00:00Z"
  recurrence_period_end_date   = "2020-09-18T00:00:00Z"
  file_format                  = "Csv"

  export_data_storage_location {
    container_id     = data.azurerm_storage_container.cost_management_container.id
    root_folder_path = "/root/updated"
  }

  export_data_options {
    type       = "Usage"
    time_frame = "WeekToDate"
  }
}

resource "azurerm_cost_anomaly_alert" "cost_anomaly_alert" {
  name            = "alertname"
  display_name    = "Alert DisplayName"
  subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  email_subject   = "My Test Anomaly Alert"
  email_addresses = ["dnsrinu143@gmail.com"]
}

resource "azurerm_resource_group_cost_management_export" "rg_cost_management_export" {
  name                         = "rg_cost_management_export"
  resource_group_id            = data.azurerm_resource_group.cost_management_rg.id
  recurrence_type              = "Monthly"
  recurrence_period_start_date = "2020-08-18T00:00:00Z"
  recurrence_period_end_date   = "2020-09-18T00:00:00Z"
  file_format                  = "Csv"

  export_data_storage_location {
    container_id     = data.azurerm_storage_container.cost_management_container.id
    root_folder_path = "/root/updated"
  }

  export_data_options {
    type       = "Usage"
    time_frame = "WeekToDate"
  }
}

resource "azurerm_subscription_cost_management_export" "subscription_cost_management_export" {
  name                         = "subscription_cost_management_export_name"
  subscription_id              = data.azurerm_subscription.cost_subscription.subscription_id
  recurrence_type              = "Monthly"
  recurrence_period_start_date = "2020-08-18T00:00:00Z"
  recurrence_period_end_date   = "2020-09-18T00:00:00Z"
  file_format                  = "Csv"

  export_data_storage_location {
    container_id     = data.azurerm_storage_container.cost_management_container.id
    root_folder_path = "/root/updated"
  }

  export_data_options {
    type       = "Usage"
    time_frame = "WeekToDate"
  }
}
