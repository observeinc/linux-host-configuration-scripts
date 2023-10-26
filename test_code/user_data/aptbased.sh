#!/bin/bash
apt-get update -y

apt-get install wget curl -y

apt install ca-certificates -y

# need to add a line for high precision timestamp
# this needs to be commented out

#$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

sudo sed -i "s/\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat/#\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat/g" /etc/rsyslog.conf
sudo systemctl restart syslog