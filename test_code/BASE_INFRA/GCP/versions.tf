terraform {
  backend "s3" {
    bucket = "sockshop-terraform-state"
    region = "us-west-2"
    key    = "content-eng/linux-host-test/gcp-thunderdome-svc-acct"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.18.0"
    }
  }
  required_version = ">= 1.2"
}
