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
  description = "Public key path"
  nullable    = true
  default     = null
}

# tflint-ignore: terraform_naming_convention
variable "PRIVATE_KEY_PATH" {
  description = "Private key path - only needed for github actions runs"
  nullable    = true
  default     = null
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