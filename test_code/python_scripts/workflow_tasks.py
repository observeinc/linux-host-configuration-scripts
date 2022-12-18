#!/usr/bin/env python3

import os


def tf_override_file(test_group="", override_file_path="../override.tf"):

    with open(override_file_path, "w+") as myfile:
        myfile.write(
            f"""
            # https://www.terraform.io/language/files/override
            terraform {{
            backend "s3" {{
                bucket = "thunderdome-terraform-state"
                region = "us-west-2"
                key    = "content-eng/gha/aws/linuxhost_{test_group}"
            }}
            }}

            provider "aws" {{
            region = "us-west-2"
            }}

            provider "google" {{
            }}

            provider "azurerm" {{
            features {{}}
            }}
        """
        )


def tf_main_file(module="", main_file_path="../main.tf"):

    with open(main_file_path, "w+") as myfile:
        if module == "aws_machines":
            myfile.write(
                f"""
                locals {{
                    name_format = var.CI == true ? "gha-lht-${{var.WORKFLOW_MATRIX_VALUE}}-%s" : "linux-host-test-%s"
                }}

                module "aws_machines" {{
                    source           = "./AWS_MACHINES"
                    PUBLIC_KEY_PATH  = var.PUBLIC_KEY_PATH
                    PRIVATE_KEY_PATH = var.PRIVATE_KEY_PATH
                    name_format        = local.name_format
                    AWS_MACHINE_FILTER = true
                    CI                 = var.CI
                    PUBLIC_KEY         = var.PUBLIC_KEY

                    providers = {{
                    aws = aws
                    }}
                }}
                """
            )


def tf_output_file(module="", output_file_path="../outputs.tf"):

    with open(output_file_path, "w+") as myfile:
        myfile.write(
            f"""
            output "fab_host_all" {{
                value = module.{module}.fab_hosts
                }}
            """
        )


def config_ini(custid="", domain="", token="", config_file_path="config.ini"):

    with open(config_file_path, "w+") as myfile:
        myfile.write(
            f"""
            [arthur-stage-tenant]
                customer_id = {custid}
                domain = {domain}
                datastream_token = {token}
            """
        )


def set_custom_vars(inputs={}):
    env_file = os.getenv("GITHUB_ENV")

    for key in inputs:
        print("key = {key}")
