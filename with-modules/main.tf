module "vnet-dev" {
  source = "./with-modules/moduals/vnet"
}

module "azure_vm_dev" {
  source = "./with-modules/moduals/vm"
}

module "data_dog_monitor" {
  source = "../with-modules/moduals/datadog"
}
