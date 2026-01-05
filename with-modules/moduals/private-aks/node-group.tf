locals {
  subnet="private_subnet"
  eks_version="1.33.5"
}
resource "azurerm_kubernetes_cluster_node_pool" "spot" {

  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = "Standard_DS2_v2"
  vnet_subnet_id        = local.subnet
  orchestrator_version  = local.eks_version
  priority              = "Spot"
  spot_max_price        = -1
  eviction_policy       = "Delete"

  enable_auto_scaling = true
  node_count          = 1
  min_count           = 1
  max_count           = 10

  node_labels = {
    role                                    = "spot"
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  node_taints = [
    "spot:NoSchedule",
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]

}
