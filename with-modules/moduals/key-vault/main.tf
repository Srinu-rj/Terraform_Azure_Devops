data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "key_rg" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_key_vault" "azure_key_vault" {
  name                       = "examplekeyvault"
  location                   = azurerm_resource_group.key_rg.location
  resource_group_name        = azurerm_resource_group.key_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}
resource "azurerm_key_vault_key" "key_vault_key_rsa" {
  name         = var.key_vault_key_name
  key_vault_id = azurerm_key_vault.azure_key_vault.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "unwrapKey", "wrapKey"
  ]
}

resource "azurerm_key_vault_secret" "acr_vault_secret" {
  name         = var.acr_key_vault_name # TODO -> name of KEY VAULT
  value        = var.acr_config_secrets # TODO -> SECRETS
  key_vault_id = azurerm_key_vault.azure_key_vault.id
}

resource "azurerm_key_vault_secret" "aks_config_secrets" {
  key_vault_id = azurerm_key_vault.azure_key_vault.id
  name         = var.aks_key_vault_name
  value        = var.aks_config_secrets
}
