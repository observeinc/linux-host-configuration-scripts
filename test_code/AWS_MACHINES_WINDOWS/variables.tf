# your local key path (assumes it exists) - this will allow you to access ec2 instances
# tflint-ignore: terraform_naming_convention
variable "PUBLIC_KEY_PATH" {
  description = "Public key path"
  nullable    = true
  default     = null
  type        = string
}

# tflint-ignore: terraform_naming_convention
variable "PRIVATE_KEY_PATH" {
  description = "Private key path"
  nullable    = true
  default     = null
  type        = string
}

# where to deploy
# tflint-ignore: terraform_naming_convention
# variable "REGION" {
#   default     = "us-west-2"
#   description = "Where resources will be deployed"
#   type        = string
# }

# appended to resource names so you can find your stuff
variable "name_format" {
  description = "Common prefix for resource names"
  type        = string
}

# tflint-ignore: terraform_naming_convention
variable "BASE_TAGS" {
  description = "base resource tags"
  type        = map(string)
  default = {
    owner        = "Observe"
    createdBy    = "terraform"
    team         = "content"
    purpose      = "test auto configuration script"
    git_repo_url = "https://github.com/observeinc/linux-host-configuration-scripts"
  }
}

# tflint-ignore: terraform_naming_convention
# variable "USE_BRANCH_NAME" {
#   default     = "main"
#   description = "git repository branch to use"
#   type        = string
# }

# tflint-ignore: terraform_naming_convention
variable "CI" {
  type        = bool
  default     = false
  description = "This variable is set to true by github actions to tell us we are running in ci"
}

# tflint-ignore: terraform_naming_convention
variable "PUBLIC_KEY" {
  description = "This value comes from a variable in github actions"
  nullable    = true
  default     = null
  type        = string
}

# tflint-ignore: terraform_naming_convention
variable "AWS_MACHINE_CONFIGS" {
  type        = map(any)
  description = "variables for supported OS"
  default = {
    
    WINDOWS_SERVER_2016 = {
      ami_instance_type = "t3.small"
      ami_id            = "ami-0d7c5eb6a3508d55c"
      ami_description   = "Microsoft Windows Server 2016 with Desktop Experience Locale English AMI provided by Amazon"
      default_user      = "Administrator"
      sleep             = 120
      user_data         = "user_data/windows_2016.ps"
    }  
    
  }
}

# tflint-ignore: terraform_naming_convention
variable "AWS_MACHINE_FILTER" {
  description = "This is used as filter agains AWS_MACHINE_CONFIGS in main.tf - if set to true then all values"
  default     = ["WINDOWS_SERVER_2016"]
  type        = any
}


