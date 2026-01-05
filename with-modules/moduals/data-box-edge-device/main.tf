resource "azurerm_resource_group" "example" {
  name     = "example-databoxedge"
  location = "West Europe"
}
# TODO -> Azure Databox Edge Device in Terraform is a resource that lets you provision and manage Microsoft’s Databox Edge hardware appliance,
#  which provides edge computing, storage, and AI inferencing capabilities.
#  In Terraform, you can either query existing devices with a data source or create/manage them with the resource azurerm_databox_edge_device.
resource "azurerm_databox_edge_device" "example" {
  name                = "example-device"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = "EdgeP_Base-Standard"
}
