output "observe_datastream_token_hostmon" {
  sensitive = true
  value     = observe_datastream_token.hostmon.secret
}

output "name_format" {
  value = local.name_format
}
