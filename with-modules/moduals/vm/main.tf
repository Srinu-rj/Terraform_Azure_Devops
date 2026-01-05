# Retriv Resource group
data "azurerm_resource_group" "aks_rg" {
  name = "aks-rg"
}
data "azurerm_virtual_network" "agent_vnet" {
  name                = "agent_vnet"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}
data "azurerm_subnet" "agent_subnet" {
  name                 = "agent_subnet"
  resource_group_name  = data.azurerm_resource_group.aks_rg.name
  virtual_network_name = data.azurerm_virtual_network.agent_vnet.name
}
data "azurerm_ssh_public_key" "local_ssh_keys" {
  name                = "sshkeyname"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}

resource "azurerm_public_ip" "public_ip" {
  name                = var.public_ip_name
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location
  allocation_method   = "Static" # Static and Dynamic
  sku = "Standard" # <-- change from Basic to Standard
}

resource "azurerm_network_interface" "ing_main" {
  name                = var.network_interface_name
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location

  ip_configuration {
    name                          = "Intenal"
    subnet_id                     = data.azurerm_subnet.agent_subnet.id
    public_ip_address_id          = azurerm_public_ip.public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_security_group" "nt_security" {
  name                = var.network_security_group
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  #ingress and Egress

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_publicIP"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "inc-security" {
  network_interface_id      = azurerm_network_interface.ing_main.id
  network_security_group_id = azurerm_network_security_group.nt_security.id
}

resource "azurerm_linux_virtual_machine" "vm_image" {
  name                = var.agent_vm_name
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  size                = var.image_size
  admin_username = var.admin_username
  admin_password = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.ing_main.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("D:/azure_keys/aks_pem_key.pub")
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite" #TODO TYPES OF
  }
}

locals {}

data "azurerm_public_ip" "public_ip" {
  name                = azurerm_public_ip.public_ip.name
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  depends_on = [azurerm_linux_virtual_machine.vm_image]
}

output "out_public_ip" {
  value = data.azurerm_public_ip.public_ip.id
}

#TODO Install Docker and Configure Self-Hosted Agent [ -> provisioner -> connection ]
# resource "null_resource" "set_up_self_hosted_vm" {
#   provisioner "remote-exec" {
#     inline= ["${file("../agent/script.sh")}"]
#     # inline= ["${file("../agent/script.sh")}"]
#     connection {
#       type = "ssh"
#       user = azurerm_linux_virtual_machine.vm.admin_password
#       user = azurerm_linux_virtual_machine.vm.admin_username
#       host = data.azurerm_public_ip.public_ip.ip_address
#       timeout = "10m"
#     }
#   }
# }
# # DISK
# resource "azurerm_managed_disk" "disk_managed" {
#   create_option        = var.create_option #"Empty"
#   location             = data.azurerm_resource_group.aks_rg.location
#   name                 = var.disk_name #"${local.vm_name}-disk1"
#   resource_group_name  = data.azurerm_resource_group.aks_rg.name
#   storage_account_type = var.storage_type
# }
# # DISK ATTACH
# resource "azurerm_virtual_machine_data_disk_attachment" "example" {
#   managed_disk_id    = azurerm_managed_disk.disk_managed.id
#   virtual_machine_id = azurerm_linux_virtual_machine.vm.id
#   lun                = "10"
#   caching            = "ReadWrite"
# }
