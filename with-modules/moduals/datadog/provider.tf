terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "3.76.0"
    }

  }
  required_version = ">= 1.1.9"
}

provider "azurerm" {
  features {}

}
