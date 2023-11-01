#!/bin/bash

uninstall_yum() {
    local td_agent="$1"

    sudo service osqueryd stop
    sudo yum erase osquery -y
    sudo rm /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery
    sudo rm /etc/osquery/osquery.conf
    sudo rm /etc/osquery/osquery.flags

    if [ "$td_agent" = true ]; then
        sudo service td-agent-bit stop
        sudo yum erase td-agent-bit -y
        sudo rm /etc/yum.repos.d/td-agent-bit.repo
        sudo rm /etc/td-agent-bit/td-agent-bit.conf
    else
        sudo service fluent-bit stop
        sudo yum erase fluent-bit -y
        sudo rm /etc/yum.repos.d/fluent-bit.repo
        sudo rm /etc/fluent-bit/fluent-bit.conf
    fi

    sudo service telegraf stop
    sudo yum erase telegraf -y
    sudo rm /etc/yum.repos.d/influxdb.repo
    sudo rm /etc/telegraf/telegraf.conf
}

uninstall_apt() {
    sudo service osqueryd stop
    sudo apt-get remove osquery -y
    sudo rm  /etc/osquery/osquery.conf
    sudo rm  /etc/osquery/osquery.flags

    sudo service td-agent-bit stop
    sudo apt-get remove td-agent-bit -y
    sudo rm /etc/td-agent-bit/td-agent-bit.conf

    sudo service telegraf stop
    sudo apt-get remove telegraf -y
    sudo rm /etc/telegraf/telegraf.conf
}

# identify OS and architecture
if [ -f /etc/os-release ]; then
    . /etc/os-release

    OS=$( echo "${ID}" | tr '[:upper:]' '[:lower:]')
    CODENAME=$( echo "${VERSION_CODENAME}" | tr '[:upper:]' '[:lower:]')
elif lsb_release &>/dev/null; then
    OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    CODENAME=$(lsb_release -cs)
else
    OS=$(uname -s)
fi

SYS_ARCH=$(uname -m)
if [[ $SYS_ARCH = "aarch64" ]]; then
    ARCH="arm64"
else
    ARCH="amd64"
fi

case ${OS} in
    amzn|amazonlinux)
        AL_VERSION=$(awk -F= '$1=="VERSION" { print $2 ;}' /etc/os-release | xargs)
        if [[ $AL_VERSION == "2023" ]]; then
            uninstall_yum
        else
            uninstall_yum true
        fi
    ;;
    rhel|centos)
        uninstall_yum true
    ;;
    ubuntu|debian)
        uninstall_apt
    ;;
esac