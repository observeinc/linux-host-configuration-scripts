locals {
  name_format = var.CI == true ? "gha-lht-${var.WORKFLOW_MATRIX_VALUE}-%s" : var.name_format
}

module "aws_machines" {
  source           = "../AWS_MACHINES"
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

# module "gcp_machines" {
#   source             = "./GCP_MACHINES"
#   public_key_path    = var.PUBLIC_KEY_PATH
#   PRIVATE_KEY_PATH   = var.PRIVATE_KEY_PATH
#   region             = "us-west1"
#   zone               = "a"
#   name_format        = local.name_format
#   GCP_COMPUTE_FILTER = ["UBUNTU_18_04_LTS", "UBUNTU_20_04_LTS", "UBUNTU_22_04_LTS", "RHEL_8", "CENTOS_8"]
#   CI                 = var.CI
#   PUBLIC_KEY         = var.PUBLIC_KEY

#   providers = {
#     google = google
#   }
# }

# module "azure_machines" {
#   source               = "./AZURE_MACHINES"
#   public_key_path      = var.PUBLIC_KEY_PATH
#   PRIVATE_KEY_PATH     = var.PRIVATE_KEY_PATH
#   location             = "West US 3"
#   name_format          = local.name_format
#   AZURE_COMPUTE_FILTER = ["UBUNTU_18_04_LTS", "UBUNTU_20_04_LTS", "UBUNTU_22_04_LTS", "RHEL_8", "CENTOS_8"]
#   CI                   = var.CI
#   PUBLIC_KEY           = var.PUBLIC_KEY
#   providers = {
#     azurerm = azurerm
#   }
# }
