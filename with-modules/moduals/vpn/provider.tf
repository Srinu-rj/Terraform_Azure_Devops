terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.1.9"
}

provider "azurerm" {
  #TODO ->  https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block

  features {
    recovery_services_vault {
      recover_soft_deleted_backup_protected_vm = true
    }
    managed_disk {
      expand_without_downtime = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    virtual_machine {
      detach_implicit_data_disk_on_deletion = false
      delete_os_disk_on_deletion            = true
      graceful_shutdown                     = false
      skip_shutdown_and_force_delete        = false
    }
    virtual_machine_scale_set {
      force_delete                  = false
      roll_instances_when_required  = true
      scale_to_zero_before_deletion = true
    }
    storage {
      data_plane_available = false
    }
  }

}
