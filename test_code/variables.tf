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

variable "CI" {
  type        = bool
  default     = false
  description = "This variable is set to true by github actions to tell us we are running in ci"
}

variable "PUBLIC_KEY" {
  description = "Public key var for running in ci"
  nullable    = true
  default     = null
}