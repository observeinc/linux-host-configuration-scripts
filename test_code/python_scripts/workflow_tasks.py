#!/usr/bin/env python3

import os
import json
import stat


def tf_override_file(cloud="", test_group="", override_file_path="../override.tf"):

    with open(override_file_path, "w+") as myfile:
        myfile.write(
            f"""
            # https://www.terraform.io/language/files/override
            terraform {{
            backend "s3" {{
                bucket = "thunderdome-terraform-state"
                region = "us-west-2"
                key    = "content-eng/gha/{cloud}/linuxhost_{test_group}"
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
        elif module == "gcp_machines":
            myfile.write(
                f"""
                locals {{
                    name_format = var.CI == true ? "gha-lht-${{var.WORKFLOW_MATRIX_VALUE}}-%s" : "linux-host-test-%s"
                }}

                module "gcp_machines" {{
                    source             = "./GCP_MACHINES"
                    public_key_path    = var.PUBLIC_KEY_PATH
                    PRIVATE_KEY_PATH   = var.PRIVATE_KEY_PATH
                    region             = "us-west1"
                    zone               = "a"
                    name_format        = local.name_format
                    GCP_COMPUTE_FILTER = []
                    CI                 = var.CI
                    PUBLIC_KEY         = var.PUBLIC_KEY

                    providers = {{
                        google = google
                    }}
                }}
                """
            )

        elif module == "azure_machines":
            myfile.write(
                f"""
                locals {{
                    name_format = var.CI == true ? "gha-lht-${{var.WORKFLOW_MATRIX_VALUE}}-%s" : "linux-host-test-%s"
                }}

                module "azure_machines" {{
                    source               = "./AZURE_MACHINES"
                    public_key_path      = var.PUBLIC_KEY_PATH
                    PRIVATE_KEY_PATH     = var.PRIVATE_KEY_PATH
                    location             = "West US 3"
                    name_format          = local.name_format
                    AZURE_COMPUTE_FILTER = ["UBUNTU_18_04_LTS", "UBUNTU_20_04_LTS", "UBUNTU_22_04_LTS", "RHEL_8", "CENTOS_8"]
                    CI                   = var.CI
                    PUBLIC_KEY           = var.PUBLIC_KEY
                    providers = {{
                        azurerm = azurerm
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


seperator = "################################"


def set_custom_vars(context_dir="context", local_test=False):
    # event_name = os.getenv("GITHUB_EVENT_NAME")
    # head_ref = os.getenv("GITHUB_HEAD_REF")
    # Opening JSON file
    with open(f"{context_dir}/github_context.json", "r") as git_hub_context_file, open(
        f"{context_dir}/matrix_context.json", "r"
    ) as matrix_context_file:

        env_file = os.getenv("GITHUB_ENV")

        # returns JSON object as
        # a dictionary
        git_hub_context_data = json.load(git_hub_context_file)
        matrix_data = json.load(matrix_context_file)

        head_ref = git_hub_context_data["head_ref"]
        event_name = git_hub_context_data["event_name"]

        print(f"head_ref = {head_ref}")
        print(f"event_name = {event_name}")

        with open(env_file, "a") as environmentFile:
            if event_name == "workflow_dispatch":
                inputs = git_hub_context_data["event"]["inputs"]
                print(f"inputs = {inputs}")

                print(seperator)
                print(f'install_script_branch={inputs["install_script_branch"]}')
                print(f'this_repo_branch={inputs["this_repo_branch"]}')
                print(f'terraform_run_destroy={inputs["terraform_run_destroy"]}')
                print(f'fail_first_test={inputs["fail_first_test"]}')
                print(f'fail_second_test={inputs["fail_second_test"]}')

                print(seperator)

                environmentFile.write(
                    f'TF_VAR_USE_BRANCH_NAME={inputs["install_script_branch"]}'
                )
                environmentFile.write(f'THIS_REPO_BRANCH={inputs["this_repo_branch"]}')
                environmentFile.write(
                    f'TF_VAR_USE_BRANCH_NAME={inputs["install_script_branch"]}'
                )
                environmentFile.write(
                    f'TERRAFORM_RUN_DESTROY={inputs["terraform_run_destroy"]}'
                )
                environmentFile.write(f'FAIL_FIRST_TEST={inputs["fail_first_test"]}')
                environmentFile.write(f'FAIL_SECOND_TEST={inputs["fail_second_test"]}')

            # if pull request don't destroy resources
            if event_name == "pull_request":
                environmentFile.write(f"TERRAFORM_RUN_DESTROY=false")
                environmentFile.write(f'THIS_REPO_BRANCH={git_hub_context_data["ref"]}')

            # value for resource names
            environmentFile.write(
                f'TF_VAR_WORKFLOW_MATRIX_VALUE={matrix_data["test_groups"]}'
            )

            # This variable tells code it running on CI server
            environmentFile.write(f'TF_VAR_CI={os.getenv("CI")}')

            # This variable gets just the branch name without url stuff
            # txt = "refs/heads/arthur/ob-14272"
            # x = re.search('(?:refs\/heads\/)(.*)', txt)

            # if x:
            # print("YES! We have a match!")
            # for group in x.groups():
            #     print(group)

            # Create directory for keys and set permissions
            home_dir = os.getenv("HOME")
            new_dir = f"{home_dir}/.ssh"
            secret_path = f"{context_dir}/private_key"

            if local_test == True:
                new_dir = f"{home_dir}/.ssh_test"
                secret_path = f"{home_dir}/.ssh/id_rsa_ec2"

            private_key_path = f"{new_dir}/github_actions"

            os.mkdir(new_dir)
            per = "700"
            os.chmod(new_dir, int(per, base=8))  # chmod 700 "$HOME/.ssh"

            #  with open(env_file, "a") as environmentFile:
            # variable for private key which is required for CI server to login to machines
            environmentFile.write(f"TF_VAR_PRIVATE_KEY_PATH={private_key_path}")

            with open(private_key_path, "w+") as private_key_file, open(
                secret_path, "r"
            ) as secret:
                for line in secret:
                    private_key_file.write(line)

            # set permissions for key file
            perk = "600"
            os.chmod(private_key_path, int(perk, base=8))

        for key in git_hub_context_data:
            print(f"key = {key}")
