output "instance" {
  value = {
    # tflint-ignore: terraform_deprecated_interpolation
    "${aws_instance.linux_host_integration.tags["Name"]}" = {
      "host"            = aws_instance.linux_host_integration.public_ip
      "instance_id"     = aws_instance.linux_host_integration.id
      "user"            = var.AWS_MACHINE_CONFIGS.default_user
      "public_ssh_link" = "ssh -i ${var.PRIVATE_KEY_PATH} ${var.AWS_MACHINE_CONFIGS.default_user}@${aws_instance.linux_host_integration.public_ip}"
      # "sleep" : var.AWS_MACHINE_CONFIGS[key].sleep
      "private_ip" = aws_instance.linux_host_integration.private_ip
      "password_data" : aws_instance.linux_host_integration.password_data
      "password_decrypted" : aws_instance.linux_host_integration.password_data == "" ? null : rsadecrypt(aws_instance.linux_host_integration.password_data, file(var.PRIVATE_KEY_PATH))
    }
  }
}
# output "instance" {
#   value = aws_instance.linux_host_integration
# }
