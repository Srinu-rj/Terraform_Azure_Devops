
data "azurerm_resource_group" "cdn_rg" {
  name = "cdn_rg"
}

resource "random_string" "storage_random" {
  length = 10
  upper   = false
  special = false
}

resource "azurerm_storage_account" "cdn_storage_account" {
  name                     =  "frontend${random_string.storage_random.result}"
  location                 = data.azurerm_resource_group.cdn_rg.location
  resource_group_name      = data.azurerm_resource_group.cdn_rg.name
  account_replication_type = "RAGRS"
  account_tier             = "Standard"
  infrastructure_encryption_enabled = true
  account_kind = "StorageV2"
  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_account_static_website" "static_web-site" {
  storage_account_id = azurerm_storage_account.cdn_storage_account.id
  error_404_document = "custom_not_found.html"
  index_document     = "custom_index.html"
}