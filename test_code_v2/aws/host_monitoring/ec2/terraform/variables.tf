variable "name_format" {
  description = "name format string"
  type        = string
  default     = "blunderdome-%s"
}

# github actions uppercases all of there vars 
# tflint-ignore: terraform_naming_convention
variable "WORKFLOW_MATRIX_VALUE" {
  type        = string
  description = "Uses value for naming resources"
  default     = "base"
}

# tflint-ignore: terraform_naming_convention
variable "CI" {
  type        = bool
  default     = false
  description = "This variable is set to true by github actions to tell us we are running in ci"
}

# tflint-ignore: terraform_naming_convention,terraform_unused_declarations
# variable "PUBLIC_KEY" {
#   description = "Public key var for running in ci"
#   nullable    = true
#   default     = null
#   type        = string
# }

variable "FULL_PATH" {
  description = "Public key var for running in ci"
  nullable    = true
  default     = null
  type        = string
}

# # tflint-ignore: terraform_naming_convention
# variable "OBSERVE_ENDPOINT" {
#   description = "A string like this with your values substituted https://[CUSTOMERID].collect.[DOMAIN].com"
#   nullable    = true
#   default     = null
#   type        = string
# }

# tflint-ignore: terraform_naming_convention
variable "OBSERVE_TOKEN_OTEL" {
  description = "A datastream token"
  nullable    = true
  default     = "TOKEN"
  type        = string
}

# tflint-ignore: terraform_naming_convention
variable "OBSERVE_TOKEN_HOST_MONITORING" {
  description = "A datastream token"
  nullable    = true
  default     = "TOKEN"
  type        = string
}

variable "OBSERVE_TOKEN_NOAGENT" {
  description = "A datastream token"
  nullable    = true
  default     = "TOKEN"
  type        = string
}


# tflint-ignore: terraform_naming_convention
variable "OBSERVE_CUSTOMER" {
  description = "Observe customer id"
  nullable    = true
  default     = null
  type        = string
}

# tflint-ignore: terraform_naming_convention,terraform_unused_declarations
variable "OBSERVE_DOMAIN" {
  description = "Observe customer domain"
  nullable    = true
  default     = null
  type        = string
}


variable "debian_machines" {
  description = "Map of Debian machines to create"
  type        = map(any)
  default = {

    DEBIAN_12_INSTALLED = {
      # ami used in testing
      ami_instance_type       = "t3.small"
      ami_id                  = "ami-0c2644caf041bb6de"
      ami_description         = "Debian 12 (HVM), EBS General Purpose (SSD) Volume Type. Community developed free GNU/Linux distribution. https://www.debian.org/"
      default_user            = "admin"
      sleep                   = 120
      host_mon_user_data_path = "user_data/aptbased_linux_configuration_script_repo.sh"
      otel_user_data_path     = "user_data/aptbased_otel_repo.sh"
      no_agent_user_data_path = "user_data/aptbased_otel_repo_noagentinstall.sh"
    }

    UBUNTU_22_04_INSTALLED = {
      # ami used in testing
      ami_instance_type       = "t3.small"
      ami_id                  = "ami-008fe2fc65df48dac"
      ami_description         = "Canonical, Ubuntu, 22.04 LTS, amd64 jammy image build on 2023-05-16"
      default_user            = "ubuntu"
      sleep                   = 120
      host_mon_user_data_path = "user_data/aptbased_linux_configuration_script_repo.sh"
      otel_user_data_path     = "user_data/aptbased_otel_repo.sh"
      no_agent_user_data_path = "user_data/aptbased_otel_repo_noagentinstall.sh"
    }

    UBUNTU_20_04_LTS_INSTALLED = {
      # ami used in testing
      ami_instance_type       = "t3.small"
      ami_id                  = "ami-0892d3c7ee96c0bf7"
      ami_description         = "Canonical, Ubuntu, 20.04 LTS, amd64 focal image build on 2021-11-29"
      default_user            = "ubuntu"
      sleep                   = 120
      host_mon_user_data_path = "user_data/aptbased_linux_configuration_script_repo.sh"
      otel_user_data_path     = "user_data/aptbased_otel_repo.sh"
      no_agent_user_data_path = "user_data/aptbased_otel_repo_noagentinstall.sh"
    }

    UBUNTU_18_04_LTS_INSTALLED = {
      ami_instance_type       = "t3.small"
      ami_id                  = "ami-0cfa91bdbc3be780c"
      ami_description         = "Canonical, Ubuntu, 18.04 LTS, amd64 bionic image build on 2022-04-11"
      default_user            = "ubuntu"
      sleep                   = 120
      host_mon_user_data_path = "user_data/aptbased_linux_configuration_script_repo.sh"
      otel_user_data_path     = "user_data/aptbased_otel_repo.sh"
      no_agent_user_data_path = "user_data/aptbased_otel_repo_noagentinstall.sh"
    }

  }
}

variable "rhel_machines" {
  description = "Map of RHEL machines to create"
  type        = map(any)
  default = {
    RHEL_8_4_0_NO_AGENT_INSTALLED = {
      ami_instance_type       = "t3.small"
      ami_id                  = "ami-0b28dfc7adc325ef4"
      ami_description         = "Red Hat Enterprise Linux 8 (HVM), SSD Volume Type"
      default_user            = "ec2-user"
      sleep                   = 120
      host_mon_user_data_path = "user_data/user_data/windows.ps"
      otel_user_data_path     = "user_data/windows_otel.ps"
      no_agent_user_data_path = "user_data/windows_noagentinstall.sh"
    }

    CENT_OS_7_INSTALLED = {
      # https://wiki.centos.org/Cloud/AWS
      # Have to run install script on this machine manually
      ami_instance_type       = "t3.small"
      ami_id                  = "ami-0686851c4e7b1a8e1"
      ami_description         = "CentOS 7.9.2009 x86_64 ami-0686851c4e7b1a8e1"
      default_user            = "centos"
      sleep                   = 120
      host_mon_user_data_path = "user_data/yum_based_linux_configuration_script_repo.sh"
      otel_user_data_path     = "user_data/yum_based_otel_repo.sh"
      no_agent_user_data_path = "user_data/yum_based_noagentinstall.sh"

    }
  }
}

variable "windows_machines" {
  description = "Map of Windows machines to create"
  type        = map(any)
  default = {
    WINDOWS_SERVER_2022_BASE_OTEL_AGENT_INSTALLED = {
      ami_instance_type = "t3.small"
      ami_id            = "ami-091f300417a06d788"
      ami_description   = "Microsoft Windows Server 2022 Full Locale English AMI provided by Amazon"
      default_user      = "Administrator"
      sleep             = 120

      host_mon_user_data_path = "user_data/user_data/windows.ps"
      otel_user_data_path     = "user_data/windows_otel.ps"
      no_agent_user_data_path = "user_data/windows_noagentinstall.sh"
    }

    WINDOWS_SERVER_2019_BASE_NO_AGENT_INSTALLED = {
      ami_instance_type = "t3.small"
      ami_id            = "ami-01baa2562e8727c9d"
      ami_description   = "Microsoft Windows Server 2022 Full Locale English AMI provided by Amazon"
      default_user      = "Administrator"
      sleep             = 120

      host_mon_user_data_path = "user_data/user_data/windows.ps"
      otel_user_data_path     = "user_data/windows_otel.ps"
      no_agent_user_data_path = "user_data/windows_noagentinstall.sh"
    }
  }
}

variable "INTEGRATION" {
  default = {
    host_mon = "host_mon_user_data_path",
    otel     = "otel_user_data_path",
    no_agent = "no_agent_user_data_path"
  }

}

# variable "CREATE_INTEGRATION" {
#   type = map(any)
#   default = {
#     host_mon = true,
#     otel     = true,
#     no_agent = true
#   }

# }

variable "MACHINES_TO_CREATE" {
  default = ["rhel", "debian", "windows"]
  type    = list(string)
}


locals {
  name_format = var.CI == true ? "gha-lht-${var.WORKFLOW_MATRIX_VALUE}-%s" : var.name_format

  OBSERVE_ENDPOINT = "https://${var.OBSERVE_CUSTOMER}.collect.${var.OBSERVE_DOMAIN}"

  CREATE_INTEGRATION = {
    host_mon = var.CREATE_HOST_MON,
    otel     = var.CREATE_OTEL,
    no_agent = var.CREATE_NOAGENT,
  }

  TOKENS = {
    host_mon = var.OBSERVE_TOKEN_HOST_MONITORING
    otel     = var.OBSERVE_TOKEN_OTEL
    no_agent = var.OBSERVE_TOKEN_NOAGENT

  }
  BRANCH = {
    host_mon = var.OBSERVE_BRANCH_HOSTMON
    otel     = var.OBSERVE_BRANCH_OTEL
    no_agent = var.OBSERVE_BRANCH_NOAGENT
  }

  PRE = "https://raw.githubusercontent.com/observeinc"
  SCRIPTS = {
    host_mon = <<EOT
    curl "https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${local.BRANCH["host_mon"]}/observe_configure_script.sh"  | bash -s -- --customer_id ${var.OBSERVE_CUSTOMER} --ingest_token ${local.TOKENS["host_mon"]} --observe_host_name "${local.OBSERVE_ENDPOINT}/" --ec2metadata TRUE --branch_input "${var.OBSERVE_BRANCH_HOSTMON}"
    EOT

    otel     = <<EOT
    curl ${local.PRE}/host-quickstart-configuration/${local.BRANCH["otel"]}/opentelemetry/linux/observe_otel_install.sh | bash -s -- --observe_collection_endpoint ${local.OBSERVE_ENDPOINT} --observe_token ${local.TOKENS["otel"]}
    EOT
    no_agent = ""
  }

  machines = {
    rhel    = var.rhel_machines
    debian  = var.debian_machines
    windows = var.windows_machines
  }

  list_of_machines = { for machine in var.MACHINES_TO_CREATE : machine => { for key, value in local.machines[machine] : key => value } }
  test_machines    = merge({}, values(local.list_of_machines)...)

  merged_map = {
    for name, integration in var.INTEGRATION :
    name => { for key, value in local.test_machines :
      key => merge(value, { USERDATA = templatefile("${path.module}/${value[integration]}", {
        OBSERVE_ENDPOINT = local.OBSERVE_ENDPOINT
        OBSERVE_TOKEN    = local.TOKENS[name]
        SCRIPT           = local.SCRIPTS[name]
        BRANCH           = local.BRANCH[name]
      }) })
  } }

}

variable "OBSERVE_BRANCH_HOSTMON" {
  description = "Github branch name"
  nullable    = true
  default     = "main"
  type        = string
}

variable "OBSERVE_BRANCH_OTEL" {
  description = "Github branch name"
  nullable    = true
  default     = "main"
  type        = string
}

variable "OBSERVE_BRANCH_NOAGENT" {
  description = "Github branch name"
  nullable    = true
  default     = "main"
  type        = string
}

variable "enable_app_content" {
  description = "Enable creation of content"
  default     = false
  type        = bool
}

variable "CREATE_HOST_MON" {
  description = "Enable creation of content"
  default     = false
  type        = bool
}

variable "CREATE_OTEL" {
  description = "Enable creation of content"
  default     = false
  type        = bool
}

variable "CREATE_NOAGENT" {
  description = "Enable creation of content"
  default     = false
  type        = bool
}
