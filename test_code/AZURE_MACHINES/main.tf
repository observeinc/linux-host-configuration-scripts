locals {
  str_f = "_"
  str_r = "-"

  compute_instances = { for key, value in var.AZURE_MACHINE_CONFIGS :
  key => value if contains(var.AZURE_COMPUTE_FILTER, key) || length(var.AZURE_COMPUTE_FILTER) == 0 }

}

resource "azurerm_resource_group" "linux_host_test" {
  name     = format(var.name_format, "linux-host-test-resources")
  location = var.location
}

resource "azurerm_linux_virtual_machine" "linux_host_test" {
  # https://azapril.dev/2020/05/12/terraform-depends_on/
  depends_on = [
    azurerm_network_interface_security_group_association.linux_host_test
  ]
  for_each            = local.compute_instances
  name                = replace(format(var.name_format, "${each.key}-machine"), local.str_f, local.str_r)
  resource_group_name = azurerm_resource_group.linux_host_test.name
  location            = azurerm_resource_group.linux_host_test.location
  size                = each.value.machine_type
  admin_username      = each.value.default_user
  network_interface_ids = [
    azurerm_network_interface.linux_host_test[each.key].id,
  ]

  admin_ssh_key {
    username   = each.value.default_user
    public_key = (var.CI) ? var.PUBLIC_KEY : file(var.public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  custom_data = filebase64(each.value.user_data)
}






