

# appended to resource names so you can find your stuff
variable "name_format" {
  description = "Common prefix for resource names"
  default     = "linux-host-test-%s"
}


variable "BASE_TAGS" {
  description = "base resource tags"
  type        = map(string)
  default = {
    owner        = "Observe"
    createdBy    = "terraform"
    creator      = "arthur"
    team         = "content"
    environment  = "thunderdome"
    purpose      = "test auto configuration script"
    git_repo_url = "https://github.com/observeinc/content-eng-create-linux-host-configuration-scripts"
  }
}


# variable "CI" {
#   type        = bool
#   default     = false
#   description = "switch for running in ci"
# }

