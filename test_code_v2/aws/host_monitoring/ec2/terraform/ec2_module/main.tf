locals {
  # machine_loop = { for key, value in var.AWS_MACHINE_CONFIGS : key => value if key == var.AWS_MACHINE_FILTER || var.AWS_MACHINE_FILTER == true }

  # compute_instances = { for key, value in var.AWS_MACHINE_CONFIGS }
  # :
  # key => value if contains(var.AWS_MACHINE_FILTER, key) || length(var.AWS_MACHINE_FILTER) == 0 }

}


# EC2 instance for linux host 
resource "aws_instance" "linux_host_integration" {
  # for_each = var.AWS_MACHINE_CONFIGS

  ami           = var.AWS_MACHINE_CONFIGS.ami_id
  instance_type = var.AWS_MACHINE_CONFIGS.ami_instance_type

  associate_public_ip_address = true

  subnet_id = var.subnet_public_id

  vpc_security_group_ids = [var.aws_security_group_public_id]
  key_name               = var.aws_key_pair_name

  user_data         = var.USERDATA
  get_password_data = can(regex("WINDOWS", var.name)) ? true : false

  root_block_device {
    volume_size = 100
  }

  tags = merge(
    var.BASE_TAGS,
    {
      Name = var.name
      # OS_KEY = each.key
    },
  )
}


