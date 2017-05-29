provider "azurerm" {
subscription_id = "d6ab6f2d-bcfb-4d29-abf9-a73b26577726"
tenant_id = "b0e5bb12-4165-446c-8ea8-3c4a83012fad"
client_id = "6d93a675-e168-401e-8933-3515456da273"
client_secret = "fd794532-d5aa-4a68-83e6-14e029e90e3d"
}

variable "region" { default = "West US"}

# Create a resource group
resource "azurerm_resource_group" "dev" {
  name     = "dev_resourcegroup"
  location = "${var.region}"
}
