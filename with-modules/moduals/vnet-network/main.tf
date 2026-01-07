terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
  }
}
locals {
  vm_rg_name             = var.vm_rg_name
  vm_location            = var.vm_location
  vm_vnet_name           = var.vm_vnet_name
  sonar_public_subnet    = var.sonar_public_subnet
  public_ip_name         = var.public_ip_name
  network_interface_name = var.network_interface_name

}
resource "azurerm_resource_group" "vm_rg" {
  name     = local.vm_rg_name
  location = local.vm_location
}

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.vm_rg.location
  name                = local.vm_vnet_name
  resource_group_name = azurerm_resource_group.vm_rg.name
  address_space       = ["13.0.0.0.0/16"]
}

resource "azurerm_subnet" "public_subnet" {
  name                 = local.sonar_public_subnet
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["13.0.0.1.0/24"]
}
resource "azurerm_public_ip" "public_ip" {
  name                = "publicip-${count.index + 1}"
  allocation_method   = "Static"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  count               = local.public_ip_name
}

resource "azurerm_network_interface" "nic" {
  name                = local.network_interface_name
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.public_subnet.id
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_security_group" "network_security_grp" {
  name                = "vm_security_group"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "22", "443", "1199"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    env = var.tag_name
  }
}

resource "azurerm_network_interface_security_group_association" "ing_network" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.network_security_grp.id
}

resource "azurerm_linux_virtual_machine" "self_hosted_agent" {
  name                  = var.linux_vm_name
  location              = azurerm_resource_group.vm_rg.location
  resource_group_name   = azurerm_resource_group.vm_rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_A2_v2"
  admin_username        = "adminuser"
  computer_name         = ""
  # One of either admin_password or admin_ssh_key must be specified. I prefer  [admin_ssh_key]
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  disable_password_authentication = false


  os_disk {
    name                 = "myosdisk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
