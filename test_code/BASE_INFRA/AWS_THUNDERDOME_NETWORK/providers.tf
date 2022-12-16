terraform {
  backend "s3" {
    bucket = "sockshop-terraform-state"
    region = "us-west-2"
    key    = "content-eng/linux-host-test/aws-thunderdome-vpc"
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "sockshop"
}

provider "aws" {
  region  = "us-west-2"
  profile = "thunderdome"
  alias   = "thunderdome"
}
