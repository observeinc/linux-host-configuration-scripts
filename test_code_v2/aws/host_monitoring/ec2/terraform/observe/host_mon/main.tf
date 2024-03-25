data "observe_workspace" "default" {
  name = "Default"
}

resource "random_pet" "test" {}

locals {
  name_format = "${random_pet.test.id}/%s"
}


resource "observe_datastream" "hostmon" {
  workspace = data.observe_workspace.default.oid
  name      = format(local.name_format, "host_mon_test")
}

resource "observe_datastream_token" "hostmon" {
  name       = format(var.name_format, "host_mon_test")
  datastream = observe_datastream.hostmon.oid
}

module "host_monitoring" {
  count  = var.enable_app_content == true ? 1 : 0
  source = "terraform.observeinc.com/observeinc/host/observe"
  # github.com/observeinc/terraform-observe-host"
  name_format = local.name_format
  workspace   = data.observe_workspace.default
  datastream  = observe_datastream.hostmon
}

resource "local_file" "observe_datastream_token_hostmon" {
  content  = observe_datastream_token.hostmon.secret
  filename = "${path.module}/observe_datastream_token_hostmon"
}

resource "local_file" "observe_name_format_hostmon" {
  content  = local.name_format
  filename = "${path.module}/observe_name_format_hostmon"
}

