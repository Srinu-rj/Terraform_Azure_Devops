resource "azurerm_resource_group" "acr_storage_bucket" {
  location = var.location
  name     = var.storage_rg_name
}
data "azurerm_resource_group" "aks-rg" {
  name = "aks-rg"
}

resource "random_string" "random_string_storage" {
  length  = 8
  upper   = false
  special = false
}
resource "azurerm_storage_account" "acr_storage_account" {
  #TODO st, prod, dev
  name                     = "st${random_string.random_string_storage.result}"
  account_tier             = var.account_tier
  location                 = azurerm_resource_group.acr_storage_bucket.location
  resource_group_name      = azurerm_resource_group.acr_storage_bucket.name
  account_replication_type = var.account_replication
}

resource "azurerm_storage_container" "storage_container" {
  name = var.storage_container
  storage_account_id = azurerm_storage_account.acr_storage_account.id
  container_access_type = "private"
}
#TODO
resource "azurerm_storage_container_immutability_policy" "example" {
  storage_container_resource_manager_id = azurerm_storage_container.storage_container.id
  immutability_period_in_days           = 14
  protected_append_writes_all_enabled   = false
  protected_append_writes_enabled       = true
}

resource "azurerm_storage_account_static_website" "example" {
  storage_account_id = azurerm_storage_account.acr_storage_account.id
  error_404_document = "custom_not_found.html"
  index_document     = "${path.module}/html/home.html"
}

# resource "azurerm_storage_blob" "blob_storage" {
#   name                   = var.blob_storage
#   storage_account_name   = azurerm_storage_account.acr_storage_account.name
#   storage_container_name = azurerm_storage_container.storage_container.name
#   type                   = var.blob_storage_type #TODO Block
#   source = "${path.module}/html/home.html" #TODO I can store any file
# }

