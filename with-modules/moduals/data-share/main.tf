resource "random_string" "data_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "data_share_rg" {
  name     = "rg-${random_string.data_suffix.result}"
  location = "West Europe"
}

resource "azurerm_data_share_account" "data_share_account" {
  name                = "datashareacct${random_string.data_suffix.result}"
  location            = azurerm_resource_group.data_share_rg.location
  resource_group_name = azurerm_resource_group.data_share_rg.name

  identity {
    type = "SystemAssigned"
  }

  tags = {
    foo = "bar"
  }
}

resource "azurerm_data_share" "data_share" {
  name        = "datashare${random_string.data_suffix.result}"
  account_id  = azurerm_data_share_account.data_share_account.id
  kind        = "CopyBased" #-> Possible values are CopyBased and InPlace. Changing this forces a new Data Share to be created.
  description = "example desc"
  terms       = "Dev"

  snapshot_schedule {
    name       = "example-ss"
    recurrence = "Day" #-> Possible values are Hour, Day, Week, Month
    start_time = "2020-04-17T04:47:52.9614956Z" # TODO -> Update to current time plus few minutes
  }
}

# TODO -> only we can share dataset_blob_storage