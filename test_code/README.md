# Running tests online
To run manually run desired cloud workflow here - https://github.com/observeinc/linux-host-configuration-scripts/actions

# Running tests locally
1. Create a you.auto.tfvars file and set local paths for PUBLIC_KEY_PATH

    Example you.auto.tfvars

    ```
    PUBLIC_KEY_PATH="/Users/me/.ssh/id_rsa.pub"
    ```

    Create an override.tf file in test_code directory and run terraform apply

    You will need credentials for AWS / Google / Azure to run terraform or you can comment out cloud(s) you don't want to test in main.tf and outputs.tf

    Example override.tf

    ```
    terraform {
    backend "local" {
        path = "relative/path/to/terraform.tfstate"
    }
    }

    provider "aws" {
    region  = "us-west-2"
    profile = "thunderdome"
    }

    provider "google" {
    }

    provider "azurerm" {
    features {}
    }
    ```

    For connection strings to virtual machines run

    ```
    terraform output -json | jq -r '.fab_host_all.value'
    ```

    main.tf modules contain filter for OS on each cloud that corresponds with values in a map variable within the modules

    you will typically want to wait about 5 minutes for all virtual machines to be available

2. fabfile.py in python_scripts will read terraform output and run observe_configure_script.sh from the given branch (in remote repository).  From within python_scripts directory follow instructions in README.md