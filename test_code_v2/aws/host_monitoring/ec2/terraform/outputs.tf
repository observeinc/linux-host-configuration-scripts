output "aws_machines_host_mon" {
  value = [for k in module.aws_machines_host_mon : k.instance]
}

output "aws_machines_host_mon_count" {
  value = length(module.aws_machines_host_mon)
}

output "aws_machines_otel" {
  value = [for k in module.aws_machines_otel : k.instance]
}

output "aws_machines_otel_count" {
  value = length(module.aws_machines_otel)
}

output "aws_machines_no_agent" {
  value = [for k in module.aws_machines_no_agent : k.instance]
}

output "aws_machines_no_agent_count" {
  value = length(module.aws_machines_no_agent)
}


output "SCRIPTS" {
  value = local.SCRIPTS
}
