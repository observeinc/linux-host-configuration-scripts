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
