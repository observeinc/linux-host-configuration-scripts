#!/bin/bash

################################
# WARNING USING THIS AS TEMPLATE FILE FOR TERRAFORM
# Percent signs are doubled to escape them
################################
apt-get update -y

apt-get install wget curl sed nano uuid-runtime ca-certificates apt-utils stress-ng cron ca-certificates -y

# need to add a line for high precision timestamp
# make syslog use precise timestamp
sudo sed -i "s/\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat/#\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat/g" /etc/rsyslog.conf
sudo systemctl restart syslog

# install otel collector
wget "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.88.0/otelcol-contrib_0.88.0_linux_amd64.deb"
dpkg -i otelcol-contrib_0.88.0_linux_amd64.deb

# create otel config
cp /etc/otelcol-contrib/config.yaml /etc/otelcol-contrib/config.OLD
rm /etc/otelcol-contrib/config.yaml

# # add collector user to syslog group
sudo usermod -a -G syslog otelcol-contrib

# install lignator log generator
# https://github.com/microsoft/lignator
# sample commands
## lignator -t "timestamp: %%{utcnow()}%%" --token-opening "%%{" --token-closing "}%%" -o /home/ubuntu/testlogs
## lignator -t "[%%{utcnow()}%%] - [%%{randomitem(INFO ,WARN ,ERROR)}%%] - I am a log for request with id: %%{uuid}%%" --token-opening "%%{" --token-closing "}%%" -o /home/ubuntu/testlogs

# install lignator log generator
# https://github.com/microsoft/lignator
# sample commands
## lignator -t "timestamp: %%{utcnow()}%%" --token-opening "%%{" --token-closing "}%%" -o /home/ubuntu/testlogs
## lignator -t "[%%{utcnow()}%%] - [%%{randomitem(INFO ,WARN ,ERROR)}%%] - I am a log for request with id: %%{uuid}%%" --token-opening "%%{" --token-closing "}%%" -o /home/ubuntu/testlogs

wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update
sudo apt-get install -y dotnet-sdk-7.0


wget https://github.com/microsoft/lignator/archive/v0.8.0.tar.gz \
&& tar xvzf v0.8.0.tar.gz \
&& cd ./lignator-0.8.0/src \
&& sudo dotnet publish -r linux-x64 -c Release -o /usr/local/bin/ -p:PublishSingleFile=true --self-contained true -p:InformationalVersion=0.8.0 \
&& lignator --version

sudo su ubuntu

mkdir /home/ubuntu/templates

# create lignator templates
# nginx access
tee /home/ubuntu/templates/nginx_access.template > /dev/null << EOT
192.168.%%{randombetween(0, 99)}%%.%%{randombetween(0, 99)}%% - - [%%{utcnow()}%%] "GET / HTTP/1.1" 200 396 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36"
EOT
# nginx error
tee /home/ubuntu/templates/nginx_error.template > /dev/null << EOT
[%%{utcnow()}%%] - [%%{randomitem(INFO ,WARN ,ERROR)}%%] - I am a log for request with id: %%{uuid}%%
EOT
# apache access
tee /home/ubuntu/templates/apache_access.template > /dev/null << EOT
192.168.%%{randombetween(0, 99)}%%.%%{randombetween(0, 99)}%% - - [%%{utcnow()}%%] "GET %%{randomitem(/cgi-bin/try/, ,/hidden/)}%% HTTP/1.0" %%{randomitem(200,400,401,403,404,405,500,502,503)}%% 3395
EOT
# apache error
tee /home/ubuntu/templates/apache_error.template > /dev/null << EOT
[%%{utcnow()}%%] [error] [client 1.2.3.4] %%{randomitem(Directory index forbidden by rule: /home/test/,Directory index forbidden by rule: /apache/web-data/test2,Client sent malformed Host header,user test: authentication failure for "/~dcid/test1": Password Mismatch)}%%
EOT

# create script to generate logs using templates
tee /home/ubuntu/genlogs.sh > /dev/null << EOT
#!/bin/bash
/usr/local/bin/lignator -t /home/ubuntu/templates --token-opening "%%{" --token-closing "}%%" -l 50 -o /home/ubuntu/logs
EOT

sudo chmod +x /home/ubuntu/genlogs.sh

# create cron jobs to generate logs and system stress
(crontab -l 2>/dev/null; echo "* * * * * /home/ubuntu/genlogs.sh >> /home/ubuntu/cron_gen.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/2 * * * * /usr/bin/stress-ng --matrix 0 -t 1m >> /home/ubuntu/cron_stress.log 2>&1") | crontab -

tee /etc/otelcol-contrib/config.yaml > /dev/null << EOT
exporters:
  logging:
    loglevel:
  otlphttp:
    endpoint: "${OBSERVE_ENDPOINT}/v1/otel"
    headers:
      authorization: "Bearer ${OBSERVE_TOKEN}"
processors:
  batch:
  resource:
    attributes:
    - key: OBSERVE_GUID
      value: $${HOSTNAME}
      action: upsert
  resourcedetection:
    detectors: [env, ec2, eks, system]
    system:
      hostname_sources: ["lookup", "cname", "dns", "os"]
receivers:
  filestats:
    include: /var/log/dpkg.log
    collection_interval: 5m
    initial_delay: 1s

  filelog/base:
    include: [/var/log/*.log, /root/*.log, /root/logs/*.log]
    include_file_path: true
    #start_at: beginning
    operators:
            #- type: regex_parser
        #regex: (?P<timestamp_field>\w+ \d+ \d+:\d+:\d+)
      - type: filter
        expr: 'body matches "otel-contrib"'
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/hostmetricsreceiver
  hostmetrics: 
    root_path: /
    collection_interval: 60s
    scrapers:
      cpu:
        metrics:
          # Default
          system.cpu.time:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          # Optional
          # system.cpu.frequency:
          #   enabled: "${OPTIONAL_METRICS_ENABLED}"
          system.cpu.logical.count:
            enabled: "${OPTIONAL_METRICS_ENABLED}"
          system.cpu.physical.count:
            enabled: "${OPTIONAL_METRICS_ENABLED}"
          system.cpu.utilization:
            enabled: "${OPTIONAL_METRICS_ENABLED}"
      disk:
        metrics:
          # Default
          system.disk.io:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.disk.io_time:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.disk.merged:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.disk.operation_time:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.disk.operations:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.disk.pending_operations:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.disk.weighted_io_time:
            enabled: "${DEFAULT_METRICS_ENABLED}"
      load:
        metrics:
          # Default
          system.cpu.load_average.15m:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.cpu.load_average.1m:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.cpu.load_average.5m:
            enabled: "${DEFAULT_METRICS_ENABLED}"
        # Config - divide by cpus
        cpu_average: true
      filesystem:
        metrics:
          # Default
          system.filesystem.inodes.usage:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.filesystem.usage:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          # Optional
          system.filesystem.utilization:
            enabled: "${OPTIONAL_METRICS_ENABLED}"
      memory:
        metrics:
        # Default
          system.memory.usage:
            enabled: "${DEFAULT_METRICS_ENABLED}"
        # Optional
          system.memory.utilization:
            enabled: "${OPTIONAL_METRICS_ENABLED}"
      network:
        metrics:
          # Default
          system.network.connections:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.network.dropped:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.network.errors:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.network.io:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.network.packets:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          # Optional
          system.network.conntrack.count:
            enabled: "${OPTIONAL_METRICS_ENABLED}"
          system.network.conntrack.max:
            enabled: "${OPTIONAL_METRICS_ENABLED}"
      paging:
        metrics:
        # Default
          system.paging.faults:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.paging.operations:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.paging.usage:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          # Optional
          system.paging.utilization:
            enabled: "${OPTIONAL_METRICS_ENABLED}"
      processes:
        metrics:
        # Default
          system.processes.count:
            enabled: "${DEFAULT_METRICS_ENABLED}"
          system.processes.created:
            enabled: "${DEFAULT_METRICS_ENABLED}"
      process:
        metrics:
        # Default
          process.cpu.time:
            enabled: "${PROCESS_DEFAULT_METRICS_ENABLED}"
          process.disk.io:
            enabled: "${PROCESS_DEFAULT_METRICS_ENABLED}"
          process.memory.usage:
            enabled: "${PROCESS_DEFAULT_METRICS_ENABLED}"
          process.memory.virtual:
            enabled: "${PROCESS_DEFAULT_METRICS_ENABLED}"
        # Optional
          process.context_switches:
            enabled: "${PROCESS_OPTIONAL_METRICS_ENABLED}"
          process.cpu.utilization:
            enabled: "${PROCESS_OPTIONAL_METRICS_ENABLED}"
          process.disk.operations:
            enabled: "${PROCESS_OPTIONAL_METRICS_ENABLED}"
          process.handles:
            enabled: "${PROCESS_OPTIONAL_METRICS_ENABLED}"
          process.open_file_descriptors:
            enabled: "${PROCESS_OPTIONAL_METRICS_ENABLED}"
          process.paging.faults:
            enabled: "${PROCESS_OPTIONAL_METRICS_ENABLED}"
          process.signals_pending:
            enabled: "${PROCESS_OPTIONAL_METRICS_ENABLED}"
          process.threads:
            enabled: "${PROCESS_OPTIONAL_METRICS_ENABLED}"
  otlp:
    protocols:
      grpc:
        include_metadata: true
      http:
        include_metadata: true
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [resource, batch]
      exporters: [otlphttp, logging]
    logs/base:
      receivers: [filelog/base]
      processors: [resource,batch]
      exporters: [otlphttp]
    metrics/two:
      receivers: [filestats]
      processors: [resource,resourcedetection,batch]
      exporters: [otlphttp]
    metrics:
      receivers: [hostmetrics, otlp]
      processors: [resource]
      exporters: [logging, otlphttp]
EOT

sudo service otelcol-contrib restart