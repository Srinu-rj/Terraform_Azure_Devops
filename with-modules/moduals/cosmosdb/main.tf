
data "azurerm_resource_group" "aks_rg" {
  name = "aks_rg"
}

#TODO Custome resource group
resource "azurerm_resource_group" "rg" {
  name     = var.database_rg_name
  location = var.database_rg_location
}

resource "random_integer" "cosmosdb_random" {
  min = 10000
  max = 99999
}
resource "azurerm_user_assigned_identity" "db_iam_identity" {
  name                = var.db_iam_identity
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}

resource "azurerm_cosmosdb_account" "cosmosdb_database" {
  name                = "${var.cosmosdb_database_name}-${random_integer.cosmosdb_random.result}"
  location            = data.azurerm_resource_group.aks_rg.location
  offer_type          = var.cosmosdb_offer_type #Standard
  resource_group_name = data.azurerm_resource_group.aks_rg.name

  automatic_failover_enabled = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }
  capabilities {
    name = "EnableMongo"
  }
  capabilities {
    name = "MongoDBv3.4"
  }
  consistency_policy {
    consistency_level = "Strong"
  }

  geo_location {
    location          = data.azurerm_resource_group.aks_rg.location
    failover_priority = 1
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.db_iam_identity.id]
  }
}
