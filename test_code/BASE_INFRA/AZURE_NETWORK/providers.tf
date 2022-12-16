terraform {
  backend "s3" {
    bucket = "sockshop-terraform-state"
    region = "us-west-2"
    key    = "content-eng/linux-host-test/azure-vpc"
  }
}

provider "azurerm" {
  features {}
}

provider "aws" {
  region  = "us-west-2"
  profile = "sockshop"
}

