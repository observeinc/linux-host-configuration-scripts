# Create public IPs
resource "azurerm_public_ip" "linux_host_test" {
  for_each            = local.compute_instances
  name                = format(var.name_format, "${each.key}_PublicIP")
  location            = azurerm_resource_group.linux_host_test.location
  resource_group_name = azurerm_resource_group.linux_host_test.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "linux_host_test" {
  for_each            = local.compute_instances
  name                = format(var.name_format, "${each.key}_nic")
  location            = azurerm_resource_group.linux_host_test.location
  resource_group_name = azurerm_resource_group.linux_host_test.name

  ip_configuration {
    name                          = format(var.name_format, "internal")
    subnet_id                     = data.azurerm_subnet.linux_host_test.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux_host_test[each.key].id
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "linux_host_test" {
  name                = format(var.name_format, "NetworkSecurityGroup")
  location            = azurerm_resource_group.linux_host_test.location
  resource_group_name = azurerm_resource_group.linux_host_test.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "linux_host_test" {
  for_each                  = local.compute_instances
  network_interface_id      = azurerm_network_interface.linux_host_test[each.key].id
  network_security_group_id = azurerm_network_security_group.linux_host_test.id
}
