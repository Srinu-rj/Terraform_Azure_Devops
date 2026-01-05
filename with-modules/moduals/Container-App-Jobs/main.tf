data "azurerm_resource_group" "aks-rg" {
  name = "aks-rg"
}

resource "azurerm_log_analytics_workspace" "container_app_analytics_jobs" {
  name                = "container_app_analytics_jobs"
  location            = data.azurerm_resource_group.aks-rg.location
  resource_group_name = data.azurerm_resource_group.aks-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "container_app_environment_jobs" {
  name                       = var.container_app_environment_name #"spring_container_app_environment"
  location                   = data.azurerm_resource_group.aks-rg.location
  resource_group_name        = data.azurerm_resource_group.aks-rg.name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.container_app_analytics_jobs.id
}

resource "azurerm_container_app_job" "spring_container_app_jobs" {
  container_app_environment_id = azurerm_container_app_environment.container_app_environment_jobs
  location                     = data.azurerm_resource_group.aks-rg.location
  name                         = var.container_job
  resource_group_name          = data.azurerm_resource_group.aks-rg.name

  replica_timeout_in_seconds = 10
  replica_retry_limit        = 10

  manual_trigger_config {
    parallelism              = 4
    replica_completion_count = 1
  }
  template {
    container {
      cpu    = 1.5
      memory = "1Gi"
      image  = "nginx:latest" #TODO Docker Or ACR images
      name   = "justfun" #TODO CONTAINER NAME
      readiness_probe {
        transport = "HTTP"
        port      = 80 #1199
      }
      liveness_probe {
        transport = "HTTP"
        port      = 80 #1199
        path      = "/health"

        header {
          name  = "Cache-Control"
          value = "no-cache"
        }

        initial_delay           = 5
        interval_seconds        = 20
        timeout                 = 2
        failure_count_threshold = 1
      }
      startup_probe {
        port      = 80 #1199
        transport = "HTTP"
      }
    }
  }
}
