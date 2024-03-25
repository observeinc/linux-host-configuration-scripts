variable "OBSERVE_TOKEN_OTEL" {
  description = "A datastream token"
  nullable    = true
  default     = "TOKEN"
  type        = string
}

module "o2" {
  source             = "../"
  OBSERVE_CUSTOMER   = "102"
  OBSERVE_DOMAIN     = "observe-o2.com"
  OBSERVE_TOKEN_OTEL = var.OBSERVE_TOKEN_OTEL
  CREATE_INTEGRATION = {
    host_mon = false,
    otel     = true,
    no_agent = false
  }

  debian_machines = {

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

