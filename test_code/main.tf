locals {
  name_format = var.CI == true ? "gha-linux-host-test-${var.WORKFLOW_MATRIX_VALUE}-%s" : "linux-host-test-%s"
}

module "aws_machines" {
  source             = "./AWS_MACHINES"
  PUBLIC_KEY_PATH    = var.PUBLIC_KEY_PATH
  PRIVATE_KEY_PATH   = var.PRIVATE_KEY_PATH
  REGION             = "us-west-2"
  name_format        = local.name_format
  AWS_MACHINE_FILTER = true
  CI                 = var.CI
  PUBLIC_KEY         = var.PUBLIC_KEY

  providers = {
    aws = aws
  }
}