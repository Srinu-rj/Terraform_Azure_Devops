aks_rg_name="aks-rg"
location = "eastus"

aks_vnet_name = "aks_vnet"
aks_vnet_cidr = ["10.0.0.0/16"] #TODO 10.0.0.0/16
aks_public_subnet_name = "aks_public_subnet"
aks_private_subnet_name = "aks_private_subnet"
aks_public_subnet_cidr = ["10.0.1.0/24"]
aks_private_subnet_cidr = ["10.0.2.0/24"]

acr_vnet_name = "acr_vnet"
acr_vnet_cidr = ["11.0.0.0/16"] #TODO 11.0.0.0/16
acr_private_subnet_name="acr_private_subnet"
acr_private_subnet_cidr = ["11.0.1.0/24"]

agent_vnet_name = "agent_vnet"
agent_vnet_cidr = ["12.0.0.0/16"]
agent_subnet_name = "agent_subnet"
agent_subnet_cidr = ["12.0.1.0/24"]



