terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "migration_rg" {
  name     = "rg-database-secure"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "migrate_vnet" {
  name                = "db-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.migration_rg.location
  resource_group_name = azurerm_resource_group.migration_rg.name
}

# Database Subnet
resource "azurerm_subnet" "migrate_db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.migration_rg.location
  virtual_network_name = azurerm_resource_group.migration_rg.name
  address_prefixes     = ["10.10.1.0/24"]
}

# Application Subnet
resource "azurerm_subnet" "migrate_app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.migration_rg.name
  virtual_network_name = azurerm_virtual_network.migrate_vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}

# Route Table
resource "azurerm_route_table" "migrate_rt" {
  name                = "db-route-table"
  location            = azurerm_resource_group.migration_rg.location
  resource_group_name = azurerm_resource_group.migration_rg.name
}

# Associate Route Table with DB Subnet
resource "azurerm_subnet_route_table_association" "db_assoc" {
  subnet_id      = azurerm_subnet.migrate_db_subnet.id
  route_table_id = azurerm_route_table.migrate_rt.id
}

# Network Security Group for DB Subnet
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  location            = azurerm_resource_group.migration_rg.location
  resource_group_name = azurerm_resource_group.migration_rg.name

  security_rule {
    name                       = "AllowAppSubnetToDB"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "10.10.2.0/24" # App subnet
    destination_address_prefix = "*"
    destination_port_range     = 5432 # PostgreSQL port
  }

  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

# Associate NSG with DB Subnet
resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
  subnet_id                 = azurerm_subnet.migrate_db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# TODO =========== MYSQL DATABASE ===========
# Source: Azure SQL Server + DB
resource "azurerm_mssql_server" "mysql_server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.migration_rg.name
  location                     = azurerm_resource_group.migration_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "sql_database" {
  name           = var.sql_db_name
  server_id      = azurerm_mssql_server.mysql_server.id
  sku_name       = "Basic"
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 2
  zone_redundant = false
}

# Allow Azure services to connect (simplified; consider IP rules or Private Link in prod)
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.mysql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# TODO =========== POSTGRES DATABASE ===========
data "azurerm_client_config" "current" {}
# Target: Azure PostgresSQL Flexible Server + DB
resource "azurerm_postgresql_flexible_server" "pg" {
  name                = var.pg_server_name
  resource_group_name = azurerm_resource_group.migration_rg.name
  location            = azurerm_resource_group.migration_rg.location

  administrator_login    = var.pg_admin_login
  administrator_password = var.pg_admin_password

  sku_name   = "B_Standard_B1ms"
  version    = var.pg_version
  storage_mb = 32768


  authentication {
    active_directory_auth_enabled = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }
  # Simplified networking; use private vnet integration in production
  zone = 1
}
resource "azurerm_postgresql_flexible_server_database" "pg_db" {
  name      = var.pg_db_name
  server_id = azurerm_postgresql_flexible_server.pg.id
  charset   = "UTF8"
  collation = "en_US.UTF8"
}

# TODO =========== MIGRATION ===========
resource "azurerm_database_migration_service" "migration_service" {
  name                = var.db_migration_service_name
  location            = azurerm_resource_group.migration_rg.location
  resource_group_name = azurerm_resource_group.migration_rg.name
  subnet_id           = azurerm_subnet.migrate_db_subnet.id
  sku_name            = var.db_migration_sku
}

# DMS Project: SQL -> PostgresSQL
resource "azurerm_database_migration_project" "migration_project" {
  name                = var.db_migration_project_name
  service_name        = azurerm_database_migration_service.migration_service.name
  resource_group_name = azurerm_resource_group.migration_rg.name
  location            = azurerm_resource_group.migration_rg.location

  source_platform = "SQL"
  target_platform = "PostgreSQL"
}
