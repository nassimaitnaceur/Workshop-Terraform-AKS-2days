/*

The following links provide the documentation for the new blocks used
in this terraform configuration file

1. azurerm_resource_group - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group

*/

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.8.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "a81225ea-83c4-4455-ac95-6e5dc66c600a"
  client_id       = "bd6d9e98-9147-4274-ba2a-849c03738104"
  client_secret   = "vgK8Q~reQf0OAA-njRuUd5LgWtbUx6KEgxaa-bVR"
  tenant_id       = "2c0ee93e-2aeb-487a-8b1e-f6742874bf9c"
  features {}
}

resource "azurerm_resource_group" "Terra-rg" {
  name     = "Terraform-Nassim-WE-rg"
  location = "WestEurope"
  Tag = "Test-Nassim"
}

resource "azurerm_virtual_network" "Terra-VNET" {
   name                = "Terraform-Nassim-WE-vnet"
   address_space       = ["10.0.0.0/16"]
   location            = azurerm_resource_group.test.location
   resource_group_name = azurerm_resource_group.test.name
 }

 resource "azurerm_subnet" "Terra-subnet" {
   name                 = "Terraform-Nassim-WE-sub"
   resource_group_name  = azurerm_resource_group.test.name
   virtual_network_name = azurerm_virtual_network.test.name
   address_prefixes     = ["10.0.2.0/24"]
 }

 resource "azurerm_public_ip" "Terra-pip" {
   name                         = "publicIPForVM"
   location                     = azurerm_resource_group.test.location
   resource_group_name          = azurerm_resource_group.test.name
   allocation_method            = "Static"
 }

resource "azurerm_network_interface" "Terra-Net-Interface" {
   count               = 2
   name                = "acctni${count.index}"
   location            = azurerm_resource_group.test.location
   resource_group_name = azurerm_resource_group.test.name

   ip_configuration {
     name                          = "testConfiguration"
     subnet_id                     = azurerm_subnet.test.id
     private_ip_address_allocation = "dynamic"
   }
 }

 resource "azurerm_managed_disk" "Terra-disk" {
   count                = 2
   name                 = "datadisk_existing_${count.index}"
   location             = azurerm_resource_group.test.location
   resource_group_name  = azurerm_resource_group.test.name
   storage_account_type = "Standard_LRS"
   create_option        = "Empty"
   disk_size_gb         = "1023"
 }

resource "azurerm_virtual_machine" "Terra-VM" {
   count                 = 2
   name                  = "acctvm${count.index}"
   location              = azurerm_resource_group.test.location
   availability_set_id   = azurerm_availability_set.avset.id
   resource_group_name   = azurerm_resource_group.test.name
   network_interface_ids = [element(azurerm_network_interface.test.*.id, count.index)]
   vm_size               = "Standard_D4s_v3"

   # Uncomment this line to delete the OS disk automatically when deleting the VM
   # delete_os_disk_on_termination = true

   # Uncomment this line to delete the data disks automatically when deleting the VM
   # delete_data_disks_on_termination = true

   storage_image_reference {
     publisher = "Canonical"
     offer     = "Windows 10 pro"
     sku       = ""
     version   = "latest"
   }

   storage_os_disk {
     name              = "myosdisk${count.index}"
     caching           = "ReadWrite"
     create_option     = "FromImage"
     managed_disk_type = "Standard_LRS"
   }

   # Optional data disks
   storage_data_disk {
     name              = "datadisk_new_${count.index}"
     managed_disk_type = "Standard_LRS"
     create_option     = "Empty"
     lun               = 0
     disk_size_gb      = "1023"
   }

   storage_data_disk {
     name            = element(azurerm_managed_disk.test.*.name, count.index)
     managed_disk_id = element(azurerm_managed_disk.test.*.id, count.index)
     create_option   = "Attach"
     lun             = 1
     disk_size_gb    = element(azurerm_managed_disk.test.*.disk_size_gb, count.index)
   }

   os_profile {
     computer_name  = "hostname"
     admin_username = "adminterraform"
     admin_password = "aptgetinstall@7"
   }

   os_profile_linux_config {
     disable_password_authentication = false
   }

   tags = {
     environment = "Test-Nassim"
   }
 }