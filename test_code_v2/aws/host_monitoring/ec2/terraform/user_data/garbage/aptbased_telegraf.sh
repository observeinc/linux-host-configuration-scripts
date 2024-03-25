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

# # add collector user to syslog group
# sudo usermod -a -G syslog otelcol-contrib

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

curl https://raw.githubusercontent.com/yasar-observe/host-configuration-scripts/yasar/init/telegraf/linux/observe_telegraf_install.sh | bash -s -- --observe_host ${OBSERVE_ENDPOINT} --observe_token ${OBSERVE_TOKEN}