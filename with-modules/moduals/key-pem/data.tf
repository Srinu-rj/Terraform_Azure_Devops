#
# data "azurerm_ssh_public_key" "local_ssh_keys" {
#   name                = var.custom_ss_key_pem
#   resource_group_name = data.azurerm_resource_group.aks_rg.name
# }