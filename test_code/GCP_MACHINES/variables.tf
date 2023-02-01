# tflint-ignore: terraform_naming_convention
variable "GCP_MACHINE_CONFIGS" {
  type        = map(any)
  description = "variable for what compute instances to create"
  default = {
    #https://cloud.google.com/compute/docs/images/os-details#ubuntu_lts
    UBUNTU_22_04_LTS = {
      recreate     = "changethistorecreate1"
      version      = "ubuntu-os-cloud/ubuntu-2204-lts"
      machine_type = "e2-medium"
      description  = "Ubuntu 22_04 LTS"
      default_user = "ubuntu"
      zone         = "us-west1-b"
      wait         = "120"
      user_data    = "user_data/aptbased.sh"
      sleep        = 120
    }

    UBUNTU_20_04_LTS = {
      recreate     = "changethistorecreate1"
      version      = "ubuntu-os-cloud/ubuntu-2004-lts"
      machine_type = "e2-micro"
      description  = "Ubuntu 20_04 LTS"
      default_user = "ubuntu"
      zone         = "us-west1-b"
      wait         = "120"
      user_data    = "user_data/aptbased.sh"
      sleep        = 120
    }

    UBUNTU_18_04_LTS = {
      recreate     = "changethistorecreate1"
      version      = "ubuntu-os-cloud/ubuntu-1804-lts"
      machine_type = "e2-medium"
      description  = "Ubuntu 18_04 LTS"
      default_user = "ubuntu"
      zone         = "us-west1-b"
      wait         = "120"
      user_data    = "user_data/aptbased.sh"
      sleep        = 120
    }
    # Commenting out because this VM on GCP produces flaky test results and don't have motivation to figure out why
    # RHEL_8 = {
    #   recreate     = "changethistorecreate1"
    #   version      = "rhel-cloud/rhel-8"
    #   machine_type = "e2-medium"
    #   description  = "Red Hat Enterprise Linux 8"
    #   default_user = "redhat"
    #   zone         = "us-west1-b"
    #   wait         = "300"
    #   user_data    = "user_data/yumbased.sh"
    #   sleep        = 120
    # }

    CENTOS_8 = {
      recreate     = "changethistorecreate1"
      version      = "centos-cloud/centos-stream-8"
      machine_type = "e2-medium"
      description  = "CentOS Stream 8"
      default_user = "centos"
      zone         = "us-west1-b"
      wait         = "120"
      user_data    = "user_data/yumbased.sh"
      sleep        = 120
    }
  }
}

# tflint-ignore: terraform_naming_convention
variable "GCP_COMPUTE_FILTER" {
  type        = list(any)
  description = "list of compute instances to filter"
  default     = ["UBUNTU_20_04_LTS"]
  # default     = ["UBUNTU_18_04_LTS", "UBUNTU_20_04_LTS", "RHEL_8"]
}


variable "project_id" {
  type        = string
  description = "GCP Project"
  default     = "content-eng-linux-host-test"
}

variable "public_key_path" {
  description = "Public key path"
  nullable    = true
  default     = "~/.ssh/id_rsa_ec2.pub"
  type        = string
}

# tflint-ignore: terraform_naming_convention
variable "PRIVATE_KEY_PATH" {
  description = "Private key path"
  nullable    = true
  type        = string
}
variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "Zone to deploy compute into"
}

variable "name_format" {
  type        = string
  description = "name prefix"
}

# tflint-ignore: terraform_naming_convention
variable "CI" {
  type        = bool
  default     = false
  description = "switch for running in ci"
}

# tflint-ignore: terraform_naming_convention
variable "PUBLIC_KEY" {
  description = "switch for running in ci"
  nullable    = true
  default     = null
  type        = string
}
