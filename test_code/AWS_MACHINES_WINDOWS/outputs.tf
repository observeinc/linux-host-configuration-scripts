output "ec2" {
  value = { for key, value in aws_instance.linux_host_integration :
    key => {
      "arn" = value.arn
      # "account"   = local.account_info[split(":", value.arn)[4]]
      "public_ip"       = value.public_ip
      "machine_name"    = key
      "user_name"       = var.AWS_MACHINE_CONFIGS[key].default_user
      "test_key"        = random_string.output[key].id
      "instance_id"     = value.id
      "public_ssh_link" = "ssh -i ${var.PRIVATE_KEY_PATH} ${var.AWS_MACHINE_CONFIGS[key].default_user}@${value.public_ip}"
    }

  }
}

output "fab_hosts" {
  value = { for key, value in aws_instance.linux_host_integration :
    "AWS_${key}" => {
      "host" = value.public_ip
      "user" = var.AWS_MACHINE_CONFIGS[key].default_user
      "connect_kwargs" = {
        "key_filename" : var.PRIVATE_KEY_PATH
        "password" = can(regex("WINDOWS", key)) ? rsadecrypt(value.password_data, file(var.PRIVATE_KEY_PATH)) : null      }     
      "public_ssh_link" = "ssh -i ${var.PRIVATE_KEY_PATH} ${var.AWS_MACHINE_CONFIGS[key].default_user}@${value.public_ip}"
      "sleep" : var.AWS_MACHINE_CONFIGS[key].sleep
    }
  }
}




# # Path to the sshd_config file
# $sshdConfigPath = "$env:ProgramData\ssh\sshd_config"

# # Read the content of the sshd_config file
# $configContent = Get-Content $sshdConfigPath

# # Search for the line containing 'PasswordAuthentication yes' and replace it with 'PasswordAuthentication no'
# $newConfigContent = $configContent -replace '#PasswordAuthentication yes', 'PasswordAuthentication no'

# # Write the modified content back to the file
# $newConfigContent | Set-Content $sshdConfigPath

# Restart-Service sshd
