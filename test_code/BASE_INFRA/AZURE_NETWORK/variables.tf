variable "location" {
  type        = string
  description = "The Azure Region in which all resources in this example should be provisioned"
  default     = "West US 3"
}

variable "name_format" {
  type        = string
  description = "name prefix"
  default     = "linux-host-test-%s"
}

# variable "CI" {
#   type        = bool
#   default     = false
#   description = "switch for running in ci"
# }


