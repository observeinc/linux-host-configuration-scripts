output "fab_hosts" {
  value = merge({ 
    for key, value in azurerm_linux_virtual_machine.linux_host_test :
    "AZURE_${key}" => {
      "host" = value.public_ip_address
      "name" = value.name
      "user" = var.AZURE_MACHINE_CONFIGS[key].default_user
      "connect_kwargs" = {
        "key_filename" : var.PRIVATE_KEY_PATH
      }
      "public_ssh_link" = "ssh -i ${var.PRIVATE_KEY_PATH} ${var.AZURE_MACHINE_CONFIGS[key].default_user}@${value.public_ip_address}"
      "sleep" : var.AZURE_MACHINE_CONFIGS[key].sleep
    }
  },
  {
    for key, value in azurerm_windows_virtual_machine.windows_host_test :
    "AZURE_${key}" => {
      "host" = value.public_ip_address
      "name" = value.name
      "user" = var.AZURE_WIN_MACHINE_CONFIGS[key].default_user
      "connect_kwargs" = {
        "key_filename" : var.PRIVATE_KEY_PATH
      }
      "public_ssh_link" = "ssh -i ${var.PRIVATE_KEY_PATH} ${var.AZURE_MACHINE_CONFIGS[key].default_user}@${value.public_ip_address}"
      "sleep" : var.AZURE_WIN_MACHINE_CONFIGS[key].sleep
    }
  }
  )
}
