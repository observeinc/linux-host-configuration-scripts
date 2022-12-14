output "fab_hosts" {
  value = { for key, value in azurerm_linux_virtual_machine.linux_host_test :
    "AZURE_${key}" => {
      "host" = value.public_ip_address
      "user" = var.AZURE_MACHINE_CONFIGS[key].default_user
      "connect_kwargs" = {
        "key_filename" : var.PRIVATE_KEY_PATH
      }
      "public_ssh_link" = "ssh -i ~/.ssh/id_rsa_ec2 ${var.AZURE_MACHINE_CONFIGS[key].default_user}@${value.public_ip_address}"
      "sleep" : var.AZURE_MACHINE_CONFIGS[key].sleep
    }
  }
}
