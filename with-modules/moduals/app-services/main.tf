resource "azurerm_app_service_environment_v3" "app_svc_env" {
  allow_new_private_endpoint_connections = false
  internal_load_balancing_mode = "web, Publishing"

  name                = "spring_app_svc_env"
  resource_group_name = azurerm_resource_group.app_services_rg.location
  subnet_id           = azurerm_subnet.app_subnet.id
  depends_on = [azurerm_subnet.app_subnet,
  ]
}
# TODO -> UPDATED
resource "azurerm_service_plan" "azure_plan" {
  location            = azurerm_resource_group.app_services_rg.location
  name                = var.app_service_plan
  os_type             = "Linux" #Linux | windows
  resource_group_name = azurerm_resource_group.app_services_rg.name
  sku_name            = var.service_plan_sku #P1v2
  app_service_environment_id = azurerm_app_service_environment_v3.app_svc_env.id
}

resource "azurerm_linux_web_app" "backend_app_deployment" {
  location            = azurerm_resource_group.app_services_rg.location
  name                = var.web_app_name # "${var.prefix}webapp"
  resource_group_name = azurerm_resource_group.app_services_rg.name
  service_plan_id     = azurerm_service_plan.azure_plan.id

  site_config {}
}
resource "azurerm_linux_web_app_slot" "git_web_app_slot" {
  app_service_id = azurerm_linux_web_app.backend_app_deployment.id
  name           = var.web_app_slot_name

  site_config {}

}
resource "azurerm_source_control_token" "scm_github_token" {
  type  = "GitHub"
  token = "ghp_sometokenvaluesecretsauce"
}
resource "azurerm_app_service_source_control" "scm_01" {
  app_id = azurerm_linux_web_app.backend_app_deployment.id
  repo_url = "https://github.com/Srinu-rj/spring-Kubernetes.git"
  branch = "main"
}
resource "azurerm_app_service_source_control_slot" "scm_02" {
  slot_id  = azurerm_linux_web_app_slot.git_web_app_slot.id
  repo_url = "https://github.com/Azure-Samples/python-docs-hello-world"
  branch   = "master"
}

#TODO -> DATABASE CONNECTION [Optional]

