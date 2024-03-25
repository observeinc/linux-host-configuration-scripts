output "observe_datastream_token_quickstart" {
  sensitive = true
  value     = observe_datastream_token.quickstart.secret
}

output "name_format" {
  value = local.name_format
}
