terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.18.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.11"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.34.0"
    }

  }
  required_version = ">= 1.2"
}
