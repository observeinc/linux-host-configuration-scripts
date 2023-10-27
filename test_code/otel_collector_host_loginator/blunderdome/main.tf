locals {
  name_format = var.CI == true ? "gha-lht-${var.WORKFLOW_MATRIX_VALUE}-%s" : var.name_format
}

module "aws_machines_blunder" {
  source           = "../../AWS_MACHINES"
  PUBLIC_KEY_PATH  = var.PUBLIC_KEY_PATH
  PRIVATE_KEY_PATH = var.PRIVATE_KEY_PATH
  # REGION             = "us-west-2"
  name_format = local.name_format
  # AWS_MACHINE_FILTER = ["AMAZON_LINUX_2", "UBUNTU_18_04_LTS", "UBUNTU_20_04_LTS", "RHEL_8_4_0", "CENT_OS_7", "AMAZON_LINUX_2023", "WINDOWS_SERVER_2019_BASE", "WINDOWS_SERVER_2022_BASE"]
  AWS_MACHINE_FILTER  = ["UBUNTU_20_04_LTS", "UBUNTU_18_04_LTS"]
  AWS_MACHINE_CONFIGS = var.AWS_MACHINE_CONFIGS
  CI                  = var.CI
  PUBLIC_KEY          = var.PUBLIC_KEY
  USERDATA = templatefile("${path.module}/user_data/aptbased.sh", {
    OBSERVE_ENDPOINT = var.OBSERVE_ENDPOINT
    OBSERVE_TOKEN    = var.OBSERVE_TOKEN
    OBSERVE_CUSTOMER = var.OBSERVE_CUSTOMER
  })

  providers = {
    aws = aws
  }
}


# ~/observe/s/aws-creds list
# ~/observe/s/aws-creds checkout observe-blunderdome

# ./dce init 
# ./dce auth
# ~/content_eng/dce-cli/dce leases create -b 100.0 -c USD -e arthur@observeinc.com -p adayton

# ~/content_eng/dce-cli/dce leases login b2c14c49-e27a-486d-be10-84e264897649 --open-browser

# export AWS_PROFILE=blunderdome
