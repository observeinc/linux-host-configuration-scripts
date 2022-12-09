variable "WORKFLOW_MATRIX_VALUE" {
  description = "Uses value for naming resources"
  default = "base"
}

variable "PUBLIC_KEY_PATH" {
  description = "Public key path"
  nullable    = true
  default     = null
}

variable "PRIVATE_KEY_PATH" {
  description = "Private key path - only needed for github actions runs"
  nullable    = true
  default     = null
}