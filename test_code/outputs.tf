output "fab_hosts_aws" {
  value = module.aws_machines.fab_hosts
}

# output "fab_hosts_gcp" {
#   value = module.gcp_machines.fab_hosts
# }

# output "fab_hosts_azure" {
#   value = module.azure_machines.fab_hosts
# }

output "fab_host_all" {
  value = merge(
    module.gcp_machines != null ? module.gcp_machines.fab_hosts : {},
    # module.aws_machines != null ? module.aws_machines.fab_hosts : {},
    # module.azure_machines != null ? module.azure_machines.fab_hosts : {},
  )
}
