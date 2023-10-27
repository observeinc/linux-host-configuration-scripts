output "gcp_ubuntu_box" {
  value = module.gcp_ubuntu_box
}

output "gcp_ubuntu_box_curl_host_mon" {
  value = <<-EOF
curl https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/main/observe_configure_script.sh  | bash -s -- --customer_id ${var.observe.customer_id} --ingest_token "${var.observe.host_datastream_token}" --observe_host_name https://${var.observe.customer_id}.collect.observeinc.com/ --config_files_clean TRUE --ec2metadata TRUE --datacenter GCP --appgroup compute_host_app_sample_env```
EOF
}
