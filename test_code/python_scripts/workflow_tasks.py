#!/usr/bin/env python3

import os

# env_file = os.getenv("GITHUB_ENV")

def tf_overide_file(test_group, override_file_path='../overide.tf'):

    with open(override_file_path, "w+") as myfile:
        myfile.write(f'''
            # https://www.terraform.io/language/files/override
            terraform {{
            backend "s3" {{
                bucket = "thunderdome-terraform-state"
                region = "us-west-2"
                key    = "content-eng/gha/aws/linuxhost_{test_group}"
            }
            }

            provider "aws" {{
            region = "us-west-2"
            }}

            provider "google" {{
            }}

            provider "azurerm" {{
            features {{}}
            }}
        ''')
