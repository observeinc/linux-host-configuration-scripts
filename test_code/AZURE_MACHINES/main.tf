locals {
  str_f = "_"
  str_r = "-"

  compute_instances = { for key, value in var.AZURE_MACHINE_CONFIGS :
  key => value if contains(var.AZURE_COMPUTE_FILTER, key) || length(var.AZURE_COMPUTE_FILTER) == 0 }

  win_instances = { for key, value in var.AZURE_WIN_MACHINE_CONFIGS :
  key => value if contains(var.AZURE_COMPUTE_FILTER, key) || length(var.AZURE_COMPUTE_FILTER) == 0 }

  combined_instances = merge(local.compute_instances, local.win_instances)

}

data "template_file" "init" {
  template = "${file("${path.module}/azure_windows.ps.tpl")}"
  vars = {
    public_key = (var.CI) ? var.PUBLIC_KEY : file(var.public_key_path)
  }
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

resource "azurerm_windows_virtual_machine" "linux_host_test" {
  # https://azapril.dev/2020/05/12/terraform-depends_on/
  depends_on = [
    azurerm_network_interface_security_group_association.linux_host_test
  ]
  for_each            = local.win_instances
  name                = replace(format(var.name_format, "${each.key}-vm"), local.str_f, local.str_r)
  computer_name       = each.value.computer_name
  resource_group_name = azurerm_resource_group.linux_host_test.name
  location            = azurerm_resource_group.linux_host_test.location
  size                = each.value.machine_type
  admin_username      = each.value.default_user
  admin_password      = each.value.default_password
  network_interface_ids = [
    azurerm_network_interface.linux_host_test[each.key].id,
  ]

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

  custom_data = filebase64(data.template_file.init.rendered)
}
