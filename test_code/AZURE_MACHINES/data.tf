# data "azurerm_virtual_network" "linux_host_test" {
#   name                = "linux-host-test-network"
#   resource_group_name = "linux-host-test-network-resources"
# }

data "azurerm_subnet" "linux_host_test" {
  name                 = "linux-host-test-internal"
  virtual_network_name = "linux-host-test-network"
  resource_group_name  = "linux-host-test-network-resources"
}
