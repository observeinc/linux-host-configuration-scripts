data "observe_workspace" "default" {
  name = "Default"
}

resource "random_pet" "test" {}

locals {
  name_format = "${random_pet.test.id}/%s"
}

resource "observe_datastream" "quickstart" {
  workspace = data.observe_workspace.default.oid
  name      = format(local.name_format, "quickstart_test")
}

resource "observe_datastream_token" "quickstart" {
  name       = format(var.name_format, "quickstart_test")
  datastream = observe_datastream.quickstart.oid
}

module "quickstart" {
  count       = var.enable_app_content == true ? 1 : 0
  source      = "terraform.observeinc.com/observeinc/host-explorer/observe"
  name_format = local.name_format
  workspace   = data.observe_workspace.default
  datastream  = observe_datastream.quickstart
}

resource "local_file" "observe_datastream_token_otel" {
  content  = observe_datastream_token.hostmon.secret
  filename = "${path.module}/observe_datastream_token_otel"
}

resource "local_file" "observe_name_format_otel" {
  content  = local.name_format
  filename = "${path.module}/observe_name_format_otel"
}
