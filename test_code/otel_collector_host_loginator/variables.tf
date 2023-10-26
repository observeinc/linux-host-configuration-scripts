variable "AWS_MACHINE_CONFIGS" {
  type        = map(any)
  description = "variables for supported OS"
  default = {

    # UBUNTU_22_04_LTS = {
    #   # ami used in testing
    #   ami_instance_type = "t3.small"
    #   ami_id            = "<NEED TO REPLACE WITH AMI in THUNDERDOME"
    #   ami_description   = "Canonical, Ubuntu, 22.04 LTS, amd64 jammy image build on 2023-05-16"
    #   default_user      = "ubuntu"
    #   sleep             = 120
    #   user_data         = "user_data/aptbased.sh"
    # }

    UBUNTU_20_04_LTS = {
      # ami used in testing
      ami_instance_type = "t3.small"
      ami_id            = "ami-0892d3c7ee96c0bf7"
      ami_description   = "Canonical, Ubuntu, 20.04 LTS, amd64 focal image build on 2021-11-29"
      default_user      = "ubuntu"
      sleep             = 120
      user_data         = "user_data/aptbased.sh"
    }

    UBUNTU_18_04_LTS = {
      ami_instance_type = "t3.small"
      ami_id            = "ami-0cfa91bdbc3be780c"
      ami_description   = "Canonical, Ubuntu, 18.04 LTS, amd64 bionic image build on 2022-04-11"
      default_user      = "ubuntu"
      sleep             = 120
      user_data         = "user_data/aptbased.sh"
    }

  }
}

variable "name_format" {
  type    = string
  default = "linux-host-test-%s"
}

# github actions uppercases all of there vars 
# tflint-ignore: terraform_naming_convention
variable "WORKFLOW_MATRIX_VALUE" {
  type        = string
  description = "Uses value for naming resources"
  default     = "base"
}

# tflint-ignore: terraform_naming_convention
variable "PUBLIC_KEY_PATH" {
  type        = string
  description = "Public key path ex - \"/Users/YOU/.ssh/id_rsa\""
  default     = null
  nullable    = true
}

# tflint-ignore: terraform_naming_convention
variable "PRIVATE_KEY_PATH" {
  description = "Private key path ex - \"/Users/YOU/.ssh/id_rsa.pub\""
  default     = null
  nullable    = true
  type        = string
}

# tflint-ignore: terraform_naming_convention
variable "CI" {
  type        = bool
  default     = false
  description = "This variable is set to true by github actions to tell us we are running in ci"
}

# tflint-ignore: terraform_naming_convention
variable "PUBLIC_KEY" {
  description = "Public key var for running in ci"
  nullable    = true
  default     = null
  type        = string
}

variable "OBSERVE_ENDPOINT" {
  description = "A string like this with your values substituted https://[CUSTOMERID].collect.[DOMAIN].com"
  nullable    = true
  default     = null
  type        = string
}

variable "OBSERVE_TOKEN" {
  description = "A datastream token"
  nullable    = true
  default     = null
  type        = string
}
