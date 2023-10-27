terraform {
  # backend "s3" {
  #   bucket = "sockshop-terraform-state"
  #   region = "us-west-2"
  #   key    = "content-eng/awd/linux_host_script_test_workspace"
  # }

  # import service account
  # terraform import "module.gcp_machines.google_service_account.compute" projects/content-eng-linux-host-test/serviceAccounts/gha-lht-base-defaults-sa@content-eng-linux-host-test.iam.gserviceaccount.com

  # backend "s3" {
  #   bucket = "thunderdome-terraform-state"
  #   region = "us-west-2"
  #   key    = "content-eng/gha/gcp/linuxhost_base_defaults"
  # }

  # backend "s3" {
  #   bucket = "thunderdome-terraform-state"
  #   region = "us-west-2"
  #   key    = "content-eng/gha/azure/linuxhost_base_defaults"
  # }

  #   backend "s3" {
  #     bucket = "thunderdome-terraform-state"
  #     region = "us-west-2"
  #     key    = "content-eng/gha/azure/linuxhost_base_defaults"
  #   }
}

provider "aws" {
  region  = "us-west-2"
  profile = "blunderdome"
}

# provider "google" {
# }

# provider "azurerm" {
#   features {}
# }
