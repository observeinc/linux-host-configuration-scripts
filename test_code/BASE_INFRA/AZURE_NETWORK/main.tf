resource "azurerm_resource_group" "linux_host_test" {
  name     = format(var.name_format, "network-resources")
  location = var.location
}

resource "azurerm_virtual_network" "linux_host_test" {
  name                = format(var.name_format, "network")
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.linux_host_test.location
  resource_group_name = azurerm_resource_group.linux_host_test.name
}

resource "azurerm_subnet" "linux_host_test" {
  name                 = format(var.name_format, "internal")
  resource_group_name  = azurerm_resource_group.linux_host_test.name
  virtual_network_name = azurerm_virtual_network.linux_host_test.name
  address_prefixes     = ["10.0.0.0/27"]
}
