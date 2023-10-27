variable "project_id" {
  type        = string
  description = "First project I want to create provider for"
}

# variable "region" {
#   type        = string
#   description = "First region I want to create provider for"
# }


variable "zone" {
  type        = string
  description = "First region I want to create provider for"
}

variable "name_format" {
  type        = string
  description = "Name format"
  default     = "test1-%s"
}

variable "observe" {
  type = object({
    domain                = optional(string)
    customer_id           = optional(string)
    otel_datastream_token = optional(string)
    host_datastream_token = optional(string)
  })
  default = {
    domain                = "YOURS"
    customer_id           = "YOURS"
    otel_datastream_token = "YOURS"
    host_datastream_token = "YOURS"
  }
  description = "observe environment datastream connection details"
}
