output "network_id" {
  value = azurerm_virtual_network.linux_host_test.id
}

output "sub_network_id" {
  value = azurerm_subnet.linux_host_test.id
}
