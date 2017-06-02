provider "azurerm" {
}

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

resource "azurerm_network_security_group" "dev" {
  name                = "dev-nwsg"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.dev.name}"
}

resource "azurerm_network_security_rule" "dev" {
  name                        = "dev0100"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.dev.name}"
  network_security_group_name = "${azurerm_network_security_group.dev.name}"
}

# Creating a public ip with 'nagap' prefix
resource "azurerm_public_ip" "dev" {
    name = "dev-public-ip"
    location = "${var.region}"
    resource_group_name = "${azurerm_resource_group.dev.name}"
    public_ip_address_allocation = "static"
    domain_name_label = "nagap"
}

resource "azurerm_network_interface" "dev" {
  name                = "dev-nic"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.dev.name}"
  network_security_group_id     = "${azurerm_network_security_group.dev.id}"

  ip_configuration {
    name                          = "devipconfig1"
    subnet_id                     = "${azurerm_subnet.dev.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.dev.id}"
  }
}

resource "azurerm_storage_account" "dev" {
  name                = "nagap2019"
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
  name                  = "dev-ubuntu"
  location              = "${var.region}"
  resource_group_name   = "${azurerm_resource_group.dev.name}"
  network_interface_ids = ["${azurerm_network_interface.dev.id}"]
  vm_size               = "Standard_A0"

storage_image_reference {
  publisher       = "Canonical"
  offer           = "UbuntuServer"
  sku             = "16.04-LTS"
  version         = "latest"
      }
  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.dev.primary_blob_endpoint}${azurerm_storage_container.dev.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "helloworld",
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
      disable_password_authentication = true

      ssh_keys {
        path = "/home/${var.username}/.ssh/authorized_keys"
        key_data = "${file("C:/dev/terransazure/ssh_keys/id_rsa.pub")}"
      }
    }

connection {
    type     = "ssh"
    host     = "${azurerm_public_ip.dev.ip_address}"
    user     = "${var.username}"
    private_key = "${file("C:/dev/terransazure/ssh_keys/id_rsa")}"
  }

provisioner "file" {
    source      = "C:/dev/terransazure/ansible/apache2.yml"
    destination = "/home/${var.username}/apache2.yml"
    connection {
        host     = "${azurerm_public_ip.dev.ip_address}"
        user     = "${var.username}"
        private_key = "${file("C:/dev/terransazure/ssh_keys/id_rsa")}"
      }
  }

  provisioner "file" {
      source      = "C:/dev/terransazure/ansible/index.html"
      destination = "/home/${var.username}/index.html"
      connection {
          host     = "${azurerm_public_ip.dev.ip_address}"
          user     = "${var.username}"
          private_key = "${file("C:/dev/terransazure/ssh_keys/id_rsa")}"
        }
    }

  provisioner "remote-exec" {
  inline = [
    "sudo apt-get install update -y",
    "sudo apt-get install ansible git -y",
    "ansible-playbook -i 'localhost,' -c local apache2.yml",
    ]
 connection {
     host     = "${azurerm_public_ip.dev.ip_address}"
     user     = "${var.username}"
     private_key = "${file("C:/dev/terransazure/ssh_keys/id_rsa")}"
   }
}
}

output "ip" {
  value = "${azurerm_public_ip.dev.ip_address}"
}

output "domain-name" {
  value = "${azurerm_public_ip.dev.fqdn}"
}
