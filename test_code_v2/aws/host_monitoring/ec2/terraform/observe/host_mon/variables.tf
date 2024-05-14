variable "name_format" {
  type        = string
  description = "Prefix for resources and datasets."
  default     = "host_mon_test/%s"
}

variable "enable_app_content" {
  type        = bool
  description = "Variable for enabling Host Montitoring app cone content"
  default     = true
}
