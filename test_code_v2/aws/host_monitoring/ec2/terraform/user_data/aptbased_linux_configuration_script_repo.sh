#!/bin/bash

################################
# WARNING USING THIS AS TEMPLATE FILE FOR TERRAFORM
# Percent signs are doubled to escape them
################################
sudo apt-get update -y

sudo apt-get install wget curl sed nano uuid-runtime ca-certificates apt-utils stress-ng cron acl ca-certificates -y

sudo apt-get install gnupg2 -y
# need to add a line for high precision timestamp
# make syslog use precise timestamp
sudo sed -i "s/\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat/#\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat/g" /etc/rsyslog.conf
sudo systemctl restart syslog

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
# identify OS and architecture
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
VERSION=$(lsb_release -rs | tr '[:upper:]' '[:lower:]')
lsb_release -rs
CODENAME=$(lsb_release -cs)

SYS_ARCH=$(uname -m)
if [[ $SYS_ARCH = "aarch64" ]]; then
    ARCH="arm64"
else
    ARCH="amd64"
fi

if [[ $VERSION == "22.04" ]]; then
    # download package with wget
    wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb

    # install package locally
    sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
fi

wget https://packages.microsoft.com/config/ubuntu/"$${VERSION}"/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0


wget https://github.com/microsoft/lignator/archive/v0.8.0.tar.gz \
&& tar xvzf v0.8.0.tar.gz \
&& cd ./lignator-0.8.0/src \
&& sudo dotnet publish -r linux-x64 -c Release -o /usr/local/bin/ -p:PublishSingleFile=true --self-contained true -p:InformationalVersion=0.8.0 \
&& lignator --version

sudo setfacl -Rm u:ubuntu:rwX /var/log 

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
/usr/local/bin/lignator -t /home/ubuntu/templates --token-opening "%%{" --token-closing "}%%" -l 50 -o /var/log/
EOT

sudo chmod +x /home/ubuntu/genlogs.sh

# create cron jobs to generate logs and system stress
(crontab -l 2>/dev/null; echo "* * * * * /home/ubuntu/genlogs.sh >> /var/log/cron_gen.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/2 * * * * /usr/bin/stress-ng --matrix 0 -t 1m >> /var/log/cron_stress.log 2>&1") | crontab -

${SCRIPT}
# Get the current timestamp
timestamp_date=$(date +"%Y-%m-%d %H:%M:%S")
timestamp_timedatectl=$(timedatectl status)

# Specify the filename
filename="/tmp/hostmon_install_complete.log"

# Write the timestamp to the file
echo "$timestamp_date" > "$filename"
echo "$timestamp_timedatectl" >> "$filename"

input="${OBSERVE_ENDPOINT}"

# Remove "https://" from the input string
OBSERVE_ENVIRONMENT="$${input#https://}"

sudo curl -o "/etc/fluent-bit/observe-monitoring-all-platforms.conf" "https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${BRANCH}/other_configs/fluent_monitoring/observe-monitoring-all-platforms.conf"
sudo curl -o "/etc/fluent-bit/observe-monitoring-linux-only.conf" "https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${BRANCH}/other_configs/fluent_monitoring/observe-monitoring-linux-only.conf"

sudo sed -i "s/REPLACE_WITH_CUSTOMER_INGEST_TOKEN/${OBSERVE_TOKEN}/g" /etc/fluent-bit/*

sudo sed -i "s/REPLACE_WITH_OBSERVE_ENVIRONMENT/$${OBSERVE_ENVIRONMENT}/g" /etc/fluent-bit/*

sudo sed -i "s/http_server  Off/http_server  On/g" /etc/fluent-bit/fluent-bit.conf

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