provider "azurerm" {
subscription_id = "d6ab6f2d-bcfb-4d29-abf9-a73b26577726"
tenant_id = "b0e5bb12-4165-446c-8ea8-3c4a83012fad"
client_id = "6d93a675-e168-401e-8933-3515456da273"
client_secret = "fd794532-d5aa-4a68-83e6-14e029e90e3d"
}

variable "region" { default = "West US"}
variable "username" { default = "adminuser" }
variable "password" { default = "Adityanivas12345" }

resource "azurerm_resource_group" "dev" {
  name     = "HelloWorld"
  location = "${var.region}"
}

resource "azurerm_virtual_network" "dev" {
  name                = "dev-vir-nw"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.dev.name}"
}

resource "azurerm_subnet" "dev" {
  name                 = "dev-subnet"
  resource_group_name  = "${azurerm_resource_group.dev.name}"
  virtual_network_name = "${azurerm_virtual_network.dev.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "dev" {
  name                = "dev-nic"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.dev.name}"
  ip_configuration {
    name                          = "devipconfig1"
    subnet_id                     = "${azurerm_subnet.dev.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_storage_account" "dev" {
  name                = "adityanivas2017"
  resource_group_name = "${azurerm_resource_group.dev.name}"
  location            = "${var.region}"
  account_type        = "Standard_LRS"
}

resource "azurerm_storage_container" "dev" {
  name                  = "dev-storage-container"
  resource_group_name   = "${azurerm_resource_group.dev.name}"
  storage_account_name  = "${azurerm_storage_account.dev.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "dev" {
  name                  = "dev-windows"
  location              = "${var.region}"
  resource_group_name   = "${azurerm_resource_group.dev.name}"
  network_interface_ids = ["${azurerm_network_interface.dev.id}"]
  vm_size               = "Standard_A0"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2012-R2-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.dev.primary_blob_endpoint}${azurerm_storage_container.dev.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "helloworld"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }
}
