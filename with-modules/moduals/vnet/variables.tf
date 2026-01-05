variable "aks_rg_name" { type = string }
variable "location" { type = string }

variable "aks_vnet_name" { type = string }
variable "aks_vnet_cidr" { type = list(string) }
variable "aks_public_subnet_name" { type = string }
variable "aks_public_subnet_cidr" { type = list(string) }
variable "aks_private_subnet_name" { type = string }
variable "aks_private_subnet_cidr" { type = list(string) }

variable "acr_vnet_name" { type = string }
variable "acr_vnet_cidr" { type = list(string) }
variable "acr_private_subnet_name" { type = string }
variable "acr_private_subnet_cidr" { type = list(string) }

variable "agent_vnet_name" { type = string }
variable "agent_vnet_cidr" { type = list(string) }
variable "agent_subnet_name" {type = string}
variable "agent_subnet_cidr" { type = list(string) }