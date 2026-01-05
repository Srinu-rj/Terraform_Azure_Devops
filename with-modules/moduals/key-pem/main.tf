
data "azurerm_resource_group" "aks_rg" {
  name = "aks-rg"
}
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# private key
resource "local_file" "private_key_file" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "D:/azure_pem"
}
# public key
resource "local_file" "public_key_file" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "D:/azure_keys/aks_pem_key.pub"
}
resource "azurerm_ssh_public_key" "custom_ss_key_pem" {
  name                ="custom_ss_key_pem"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location
  public_key          = tls_private_key.ssh_key.public_key_openssh #TODO only expose PUBLIC_KEY
}

data "azurerm_ssh_public_key" "local_ssh_keys" {
  name                = "custom_ss_key_pem"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}