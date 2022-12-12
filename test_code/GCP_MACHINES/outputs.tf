output "fab_hosts" {
  value = { for key, value in google_compute_instance.instances :
    "GCP_${key}" => {
      "host" = value.network_interface[0].access_config[0].nat_ip
      "user" = var.GCP_MACHINE_CONFIGS[key].default_user
      "connect_kwargs" = {
        "key_filename" : var.PRIVATE_KEY_PATH
      }
      "public_ssh_link" = "ssh -i ~/.ssh/id_rsa_ec2 ${var.GCP_MACHINE_CONFIGS[key].default_user}@${value.network_interface[0].access_config[0].nat_ip}"
      "sleep" : var.GCP_MACHINE_CONFIGS[key].sleep
    }
  }
}

# output "compute_instances" {
#   sensitive = true
#   value = { for key, value in google_compute_instance.instances :
#     key => {
#       name                      = value.name
#       public_ip                 = length(value.network_interface[0].access_config) == 0 ? "" : value.network_interface[0].access_config[0].nat_ip
#       public_ssh_link           = length(value.network_interface[0].access_config) == 0 ? "" : "ssh -i ~/.ssh/id_rsa_ec2 ${local.compute_map[key].default_user}@${value.network_interface[0].access_config[0].nat_ip}"
#       public_vm_key_file_create = "vi ~/.ssh/id_rsa_ec2"
#       private_ssh_link          = "ssh -i ~/.ssh/id_rsa_ec2 ${local.compute_map[key].default_user}@${value.network_interface[0].network_ip}"
#       # user_data       = value.metadata_startup_script
#       default_user = local.compute_map[key].default_user
#       host_script  = "curl \"https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/main/observe_configure_script.sh\" | bash -s -- --customer_id \"${var.observe.customer_id}\" --ingest_token \"${var.observe.datastream_token}\" --observe_host_name https://${var.observe.customer_id}.collect.${var.observe.domain}/ --config_files_clean TRUE --ec2metadata FALSE --datacenter GCP --appgroup MY_APP_GROUP"
#     }
#     # key => value
#   }
# }
