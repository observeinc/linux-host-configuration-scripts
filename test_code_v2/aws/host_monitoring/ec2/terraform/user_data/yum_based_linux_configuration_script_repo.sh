#!/bin/bash
yum update -y

yum install curl -y

yum install wget -y

yum install ca-certificates -y

${SCRIPT}

# Get the current timestamp
timestamp_date=$(date +"%Y-%m-%d %H:%M:%S")
timestamp_timedatectl=$(timedatectl status)

# Specify the filename
filename="/tmp/hostmon_install_complete.log"

# Write the timestamp to the file
echo "$timestamp_date" > "$filename"
echo "$timestamp_timedatectl" >> "$filename"

# create script to generate logs using templates
sudo tee /etc/fluent-bit/observe-timestamp.conf > /dev/null << EOT
[FILTER]
    Name record_modifier
    Match *
# if you want to group your servers into an application group
# [e.g. Proxy nodes] so you have have custom alert levels for them
# uncomment this next line
    #REPLACE_WITH_OBSERVE_APP_GROUP_OPTION
    Record host $${HOSTNAME}
    Record datacenter hostmon_test
    Record obs_ver 20230412
    Remove_key _MACHINE_ID
[INPUT]
    name tail
    tag  tail_hostmon_install_complete
    Path_Key path
    path /tmp/hostmon_install_complete.log
    Read_from_Head true
[OUTPUT]
    name        http
    match       tail_hostmon_install_complete
    host        ${trimprefix("${OBSERVE_ENDPOINT}", "https://")}
    port        443
    URI         /v1/http/fluentbit/hostmon_install_complete
    Format      msgpack
    Header      X-Observe-Decoder fluent
    Header      Authorization Bearer ${OBSERVE_TOKEN}
    Compress    gzip
    tls         on
EOT

sudo service fluent-bit restart