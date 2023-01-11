locals {
  name_format = var.CI == true ? "gha-lht-${var.WORKFLOW_MATRIX_VALUE}-%s" : "linux-host-test-%s"
}

module "aws_machines" {
  source           = "./AWS_MACHINES"
  PUBLIC_KEY_PATH  = var.PUBLIC_KEY_PATH
  PRIVATE_KEY_PATH = var.PRIVATE_KEY_PATH
  # REGION             = "us-west-2"
  name_format        = local.name_format
  AWS_MACHINE_FILTER = ["AMAZON_LINUX_2", "UBUNTU_18_04_LTS", "UBUNTU_20_04_LTS", "UBUNTU_22_04_LTS", "RHEL_8", "CENTOS_8"]
  CI                 = var.CI
  PUBLIC_KEY         = var.PUBLIC_KEY

  providers = {
    aws = aws
  }
}

module "gcp_machines" {
  source             = "./GCP_MACHINES"
  public_key_path    = var.PUBLIC_KEY_PATH
  PRIVATE_KEY_PATH   = var.PRIVATE_KEY_PATH
  region             = "us-west1"
  zone               = "a"
  name_format        = local.name_format
  GCP_COMPUTE_FILTER = ["UBUNTU_18_04_LTS", "UBUNTU_20_04_LTS", "UBUNTU_22_04_LTS", "RHEL_8", "CENTOS_8"]
  CI                 = var.CI
  PUBLIC_KEY         = var.PUBLIC_KEY

  providers = {
    google = google
  }
}

module "azure_machines" {
  source               = "./AZURE_MACHINES"
  public_key_path      = var.PUBLIC_KEY_PATH
  PRIVATE_KEY_PATH     = var.PRIVATE_KEY_PATH
  location             = "West US 3"
  name_format          = local.name_format
  AZURE_COMPUTE_FILTER = ["UBUNTU_18_04_LTS", "UBUNTU_20_04_LTS", "UBUNTU_22_04_LTS", "RHEL_8", "CENTOS_8"]
  CI                   = var.CI
  PUBLIC_KEY           = var.PUBLIC_KEY
  providers = {
    azurerm = azurerm
  }
}
