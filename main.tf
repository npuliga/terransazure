provider "azurerm" {
subscription_id = "d6ab6f2d-bcfb-4d29-abf9-a73b26577726"
tenant_id = "b0e5bb12-4165-446c-8ea8-3c4a83012fad"
client_id = "6d93a675-e168-401e-8933-3515456da273"
client_secret = "fd794532-d5aa-4a68-83e6-14e029e90e3d"
}

resource "azurerm_resource_group" "${var.env}" {
  name     = "HelloWorld"
  location = "${var.region}"
}

resource "azurerm_virtual_network" "${var.env}" {
  name                = "${var.env}-vir-nw"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.${var.env}.name}"
}

resource "azurerm_subnet" "${var.env}" {
  name                 = "${var.env}-subnet"
  resource_group_name  = "${azurerm_resource_group.${var.env}.name}"
  virtual_network_name = "${azurerm_virtual_network.${var.env}.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "${var.env}" {
  name                = "${var.env}-nic"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.${var.env}.name}"
  ip_configuration {
    name                          = "${var.env}ipconfig1"
    subnet_id                     = "${azurerm_subnet.${var.env}.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_storage_account" "${var.env}" {
  name                = "adityanivas2017"
  resource_group_name = "${azurerm_resource_group.${var.env}.name}"
  location            = "${var.region}"
  account_type        = "Standard_LRS"
}

resource "azurerm_storage_container" "${var.env}" {
  name                  = "${var.env}-storage-container"
  resource_group_name   = "${azurerm_resource_group.${var.env}.name}"
  storage_account_name  = "${azurerm_storage_account.${var.env}.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "${var.env}" {
  name                  = "${var.env}-windows"
  location              = "${var.region}"
  resource_group_name   = "${azurerm_resource_group.${var.env}.name}"
  network_interface_ids = ["${azurerm_network_interface.${var.env}.id}"]
  vm_size               = "Standard_A0"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2012-R2-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.${var.env}.primary_blob_endpoint}${azurerm_storage_container.${var.env}.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "helloworld"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }
}
