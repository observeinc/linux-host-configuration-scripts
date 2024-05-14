module "aws_vpc" {
  source      = "./vpc_module"
  name_format = local.name_format
}

module "aws_key_pair" {
  source      = "./keypair_module"
  name_format = local.name_format
}

locals {
  PRIVATE_KEY_PATH = var.FULL_PATH != null ? "${var.FULL_PATH}/${module.aws_key_pair.aws_key_path}" : module.aws_key_pair.aws_key_path
}

module "aws_machines_host_mon" {
  for_each                     = local.CREATE_INTEGRATION["host_mon"] == true ? local.merged_map["host_mon"] : {}
  source                       = "./ec2_module"
  subnet_public_id             = module.aws_vpc.subnet_public_id
  aws_security_group_public_id = module.aws_vpc.aws_security_group_public_id
  aws_key_pair_name            = module.aws_key_pair.aws_key_pair_name

  PRIVATE_KEY_PATH = local.PRIVATE_KEY_PATH
  # tflint-ignore: terraform_deprecated_interpolation
  name = format(local.name_format, "${each.key} - host_mon")

  AWS_MACHINE_CONFIGS = each.value

  USERDATA = each.value.USERDATA
}


module "aws_machines_otel" {
  for_each                     = local.CREATE_INTEGRATION["otel"] == true ? local.merged_map["otel"] : {}
  source                       = "./ec2_module"
  subnet_public_id             = module.aws_vpc.subnet_public_id
  aws_security_group_public_id = module.aws_vpc.aws_security_group_public_id
  aws_key_pair_name            = module.aws_key_pair.aws_key_pair_name

  PRIVATE_KEY_PATH = local.PRIVATE_KEY_PATH
  # tflint-ignore: terraform_deprecated_interpolation
  name = format(local.name_format, "${each.key} - otel")

  AWS_MACHINE_CONFIGS = each.value

  USERDATA = each.value.USERDATA

}

module "aws_machines_no_agent" {
  for_each                     = local.CREATE_INTEGRATION["no_agent"] == true ? local.merged_map["no_agent"] : {}
  source                       = "./ec2_module"
  subnet_public_id             = module.aws_vpc.subnet_public_id
  aws_security_group_public_id = module.aws_vpc.aws_security_group_public_id
  aws_key_pair_name            = module.aws_key_pair.aws_key_pair_name

  PRIVATE_KEY_PATH = local.PRIVATE_KEY_PATH
  # tflint-ignore: terraform_deprecated_interpolation
  name = format(local.name_format, "${each.key} - no_agent")

  AWS_MACHINE_CONFIGS = each.value

  USERDATA = each.value.USERDATA

}

resource "local_file" "aws_machines_host_mon_count" {
  content  = length(module.aws_machines_host_mon)
  filename = "${path.module}/aws_machines_host_mon_count"
}

resource "local_file" "aws_machines_otel_count" {
  content  = length(module.aws_machines_host_mon)
  filename = "${path.module}/aws_machines_otel_count"
}

resource "local_file" "aws_machines_no_agent_count" {
  content  = length(module.aws_machines_host_mon)
  filename = "${path.module}/aws_machines_no_agent_count"
}
