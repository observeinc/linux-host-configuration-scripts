module "gcp_ubuntu_box" {
  source = "../helper_modules/gcp/compute_ubuntu_attached_bucket"
  # region      = var.region
  zone        = var.zone
  project_id  = var.project_id
  name_format = var.name_format
  compute_values = {
    UBUNTU_20_04_LTS = {
      recreate       = "changethistorecreate1"
      version        = "ubuntu-os-cloud/ubuntu-2004-lts"
      machine_type   = "e2-standard-2"
      description    = "Ubuntu 20_04 LTS"
      default_user   = "ubuntu"
      wait           = "120"
      user_data_file = "ubuntu_user_data.sh"
    }
  }
  compute_filter = ["UBUNTU_20_04_LTS"]
  open_ports     = ["22", "4317", "4318"]


  # https://opentelemetry.io/docs/collector/getting-started/#deb-installation
  metadata_startup_script = <<-EOF

echo "
receivers:
  otlp:
    protocols:
      grpc:
      http:

processors:
  batch:

exporters:
  logging:
    logLevel: debug
  otlphttp:
    endpoint: "https://collect.${var.observe.domain}/v1/otel"
    headers:
      'Authorization': 'Bearer ${var.observe.customer_id} ${var.observe.otel_datastream_token}'
  prometheusremotewrite:
    endpoint: "https://collect.${var.observe.domain}/v1/prometheus"
    headers:
      'Authorization': 'Bearer ${var.observe.customer_id} ${var.observe.otel_datastream_token}'

extensions:
  health_check:
  pprof:
  zpages:

service:
  extensions: [health_check,pprof,zpages]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlphttp]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheusremotewrite]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
  " > /home/ubuntu/otel-collector-config.yaml

sudo apt-get -y install wget systemctl

wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.69.0/otelcol_0.69.0_linux_amd64.deb

sudo dpkg -i otelcol_0.69.0_linux_amd64.deb

sudo mv /etc/otelcol/config.yaml /etc/otelcol/config.yaml.OLD

sudo cp /home/ubuntu/otel-collector-config.yaml /etc/otelcol/config.yaml

sudo systemctl restart otelcol

# Install host app monitoring
curl https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/main/observe_configure_script.sh  | bash -s -- --customer_id ${var.observe.customer_id} --ingest_token "${var.observe.host_datastream_token}" --observe_host_name https://${var.observe.customer_id}.collect.${var.observe.domain}/ --config_files_clean TRUE --ec2metadata FALSE --datacenter GCP --appgroup compute_host_app_sample_env

  EOF
}
