# tflint-ignore: terraform_naming_convention
variable "AZURE_MACHINE_CONFIGS" {
  description = "variable for what compute instances to create"
  type        = map(any)
  default = {
    # https://az-vm-image.info/
    # https://learn.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
    # https://learn.microsoft.com/en-us/azure/virtual-machines/linux/endorsed-distros
    # az vm image list -p canonical -o table --all | grep 22_04-lts    
    UBUNTU_22_04_LTS = {
      recreate     = "changethistorecreate1"
      machine_type = "Standard_DS1_v2"
      description  = "Ubuntu 22_04 LTS"
      default_user = "ubuntu"
      wait         = "120"
      user_data    = "user_data/aptbased.sh"
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts"
        version   = "latest"
      }
      sleep = 120
    }

    UBUNTU_20_04_LTS = {
      recreate     = "changethistorecreate1"
      machine_type = "Standard_DS1_v2"
      description  = "Ubuntu 20_04 LTS"
      default_user = "ubuntu"
      wait         = "120"
      user_data    = "user_data/aptbased.sh"
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts"
        version   = "latest"
      }
      sleep = 120
    }

    UBUNTU_18_04_LTS = {
      recreate     = "changethistorecreate1"
      machine_type = "Standard_DS1_v2"
      description  = "Ubuntu 18_04 LTS"
      default_user = "ubuntu"
      wait         = "120"
      user_data    = "user_data/aptbased.sh"
      sleep        = 120
      source_image_reference = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
      }
    }
    # az vm image list -p redhat -o table --all | grep 8  
    RHEL_8 = {
      recreate     = "changethistorecreate1"
      machine_type = "Standard_DS1_v2"
      description  = "Red Hat Enterprise Linux 8"
      default_user = "redhat"
      wait         = "300"
      user_data    = "user_data/yumbased.sh"
      source_image_reference = {
        publisher = "RedHat"
        offer     = "RHEL"
        sku       = "8-LVM"
        version   = "latest"
      }
      sleep = 120
    }

    CENTOS_8 = {
      recreate     = "changethistorecreate1"
      machine_type = "Standard_DS1_v2"
      description  = "CentOS Stream 8"
      default_user = "centos"
      wait         = "120"
      user_data    = "user_data/yumbased.sh"
      source_image_reference = {
        publisher = "OpenLogic"
        offer     = "CentOS-LVM"
        sku       = "8-lvm"
        version   = "latest"
      }
      sleep = 120

    }
  }
}

# tflint-ignore: terraform_naming_convention
variable "AZURE_COMPUTE_FILTER" {
  type        = list(any)
  description = "list of compute instances to filter"
  default     = ["UBUNTU_20_04_LTS"]
  # default     = ["UBUNTU_18_04_LTS", "UBUNTU_20_04_LTS", "RHEL_8"]
}

# variable "project_id" {
#   type        = string
#   description = "GCP Project"
#   default     = "content-eng-linux-host-test"
# }

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

variable "location" {
  type        = string
  description = "The Azure Region in which all resources in this example should be provisioned"
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


