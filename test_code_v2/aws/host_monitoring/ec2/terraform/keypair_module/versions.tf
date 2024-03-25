# https://www.terraform.io/language/expressions/version-constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.11"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
  }
  required_version = ">= 1.2"
}
