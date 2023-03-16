variable "project_id" {
  type        = string
  description = "GCP Project"
  default     = "content-eng-linux-host-test"
}

variable "name_format" {
  type        = string
  description = "name prefix"
  default     = "gha-lht-base-defaults"
}
