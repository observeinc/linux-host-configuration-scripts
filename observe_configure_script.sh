#!/bin/bash
END_OUTPUT="END_OF_OUTPUT"

cd ~ || exit && echo "$SPACER $END_OUTPUT $SPACER"

config_file_directory="$HOME/observe_config_files"


getConfigurationFiles(){
    local branch_replace="$1"
    local SPACER
    SPACER=$(generateSpacer)
    if [ ! -d "$config_file_directory" ]; then
      mkdir "$config_file_directory"
      echo "$SPACER $config_file_directory CREATED $SPACER"
    else
      rm -f "${config_file_directory:?}"/*
      echo "$SPACER"
      echo "$config_file_directory DELETED"
      echo "$SPACER"
      ls "$config_file_directory"
      echo "$SPACER"
    fi

    if [ ! -f "$config_file_directory/osquery.conf" ]; then
      url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch_replace}/config_files/osquery.conf"
      filename="$config_file_directory/osquery.conf"

      echo "$SPACER"
      echo "filename = $filename"
      echo "$SPACER"
      echo "url = $url"
      curl "$url" > "$filename"

      echo "$SPACER"
      echo "$filename created"
      echo "$SPACER"
    fi

    if [ ! -f "$config_file_directory/telegraf.conf" ]; then
      url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch_replace}/config_files/telegraf.conf"
      filename="$config_file_directory/telegraf.conf"

      echo "$SPACER"
      echo "filename = $filename"
      echo "$SPACER"
      echo "url = $url"
      curl "$url" > "$filename"

      echo "$SPACER"
      echo "$filename created"
      echo "$SPACER"
    fi

    if [ ! -f "$config_file_directory/td-agent-bit.conf" ]; then
      url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch_replace}/config_files/td-agent-bit.conf"
      filename="$config_file_directory/td-agent-bit.conf"

      echo "$SPACER"
      echo "filename = $filename"
      echo "$SPACER"
      echo "url = $url"
      curl "$url" > "$filename"

      echo "$SPACER"
      echo "$filename created"
      echo "$SPACER"
    fi

    if [ ! -f "$config_file_directory/observe-linux-host.conf" ]; then
      url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch_replace}/config_files/observe-linux-host.conf"
      filename="$config_file_directory/observe-linux-host.conf"

      echo "$SPACER"
      echo "filename = $filename"
      echo "$SPACER"
      echo "url = $url"
      curl "$url" > "$filename"

      echo "$SPACER"
      echo "$filename created"
      echo "$SPACER"
    fi

    if [ ! -f "$config_file_directory/observe-jenkins.conf" ]; then
      url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch_replace}/config_files/observe-jenkins.conf"
      filename="$config_file_directory/observe-jenkins.conf"

      echo "$SPACER"
      echo "filename = $filename"
      echo "$SPACER"
      echo "url = $url"
      curl "$url" > "$filename"

      echo "$SPACER"
      echo "$filename created"
      echo "$SPACER"
    fi

    if [ ! -f "$config_file_directory/osquery.flags" ]; then
      url="https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/${branch_replace}/config_files/osquery.flags"
      filename="$config_file_directory/osquery.flags"

      echo "$SPACER"
      echo "filename = $filename"
      echo "$SPACER"
      echo "url = $url"
      curl "$url" > "$filename"

      echo "$SPACER"
      echo "$filename created"
      echo "$SPACER"
    fi
}

generateTestKey(){
  echo "${OBSERVE_TEST_RUN_KEY}"
}

if [ -f /etc/os-release ]; then
    #shellcheck disable=SC1091
    . /etc/os-release

    OS=$( echo "${ID}" | tr '[:upper:]' '[:lower:]')
    CODENAME=$( echo "${VERSION_CODENAME}" | tr '[:upper:]' '[:lower:]')
elif lsb_release &>/dev/null; then
    OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    CODENAME=$(lsb_release -cs)
else
    OS=$(uname -s)
fi

# used for terminal output
generateSpacer(){
  echo "###########################################"
}

curlObserve(){
  local message="$1"
  local path_suffix="$2"
  local result="$3"

  curl https://"${OBSERVE_ENVIRONMENT}"/v1/http/script_validation/"${path_suffix}" \
  -H "Authorization: Bearer ${ingest_token}" \
  -H "Content-type: application/json" \
  -d "{\"data\": {\"datacenter\": \"${DEFAULT_OBSERVE_DATA_CENTER}\", \"host\": \"${DEFAULT_OBSERVE_HOSTNAME}\",\"result\": \"${result}\",\"message\": \"${message}\", \"os\": \"${TERRAFORM_REPLACE_OS_VALUE}\" }}"

}

printHelp(){
      echo "$SPACER"
      echo "## HELP CONTENT"
      echo "$SPACER"
      echo "### Required inputs"
      echo "- Required --customer_id YOUR_OBSERVE_CUSTOMERID "
      echo "- Required --ingest_token YOUR_OBSERVE_DATA_STREAM_TOKEN "
      echo "## Optional inputs"
      echo "- Optional --observe_host_name - Defaults to https://<YOUR_OBSERVE_CUSTOMERID>.collect.observeinc.com/ "
      echo "- Optional --config_files_clean TRUE or FALSE - Defaults to FALSE "
      echo "    - controls whether to delete created config_files temp directory"
      echo "- Optional --ec2metadata TRUE or FALSE - Defaults to FALSE "
      echo "    - controls fluentbit config for whether to use default ec2 metrics "
      echo "- Optional --datacenter defaults to AWS"
      echo "- Optional --appgroup id supplied sets value in fluentbit config"
      echo "- Optional --branch_input branch of repository to pull scrips and config files from -Defaults to main"
      echo "- Optional --validate_endpoint of observe_hostname using customer_id and ingest_token -Defaults to TRUE"
      echo "- Optional --module to use for installs -Defaults to linux_host which installs osquery, fluentbit and telegraf"
      echo "    can be combined with jenkins flag which add a config to fluentbit or only jenkons flag which only installs fluent bit with configs"
      echo "- Optional --observe_jenkins_path used in combination with jenkins module - location of jenkins logs"
      echo "***************************"
      echo "### Sample command:"
      echo "\`\`\` curl https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/main/observe_configure_script.sh  | bash -s -- --customer_id YOUR_CUSTOMERID --ingest_token YOUR_DATA_STREAM_TOKEN --observe_host_name https://<YOUR_CUSTOMERID>.collect.observeinc.com/ --config_files_clean TRUE --ec2metadata TRUE --datacenter MY_DATA_CENTER --appgroup MY_APP_GROUP\`\`\`"
      echo "***************************"
}

requiredInputs(){
      echo "$SPACER"
      echo "* Error: Invalid argument.*"
      echo "$SPACER"
      printVariables
      printHelp
      echo "$SPACER"
      echo "$END_OUTPUT"
      echo "$SPACER"
      exit 1

}

printVariables(){
      echo "$SPACER"
      echo "* VARIABLES *"
      echo "$SPACER"
      echo "customer_id: $customer_id"
      echo "ingest_token: $ingest_token"
      echo "observe_host_name: $observe_host_name"
      echo "config_files_clean: $config_files_clean"
      echo "ec2metadata: $ec2metadata"
      echo "datacenter: $datacenter"
      echo "appgroup: $appgroup"
      echo "testeject: $testeject"
      echo "validate_endpoint: $validate_endpoint"
      echo "branch_input: $branch_input"
      echo "module: $module"
      echo "observe_jenkins_path: ${observe_jenkins_path}"
      echo "$SPACER"
}

testEject(){
local bail="$1"
local bailPosition="$2"
if [[ "$bail" == "$bailPosition" ]]; then
    echo "$SPACER"
    echo "$SPACER"
    echo " TEST EJECTION "
    echo "Position = $bailPosition"
    echo "$SPACER"
    echo "$END_OUTPUT"
    echo "$SPACER"
    echo "$SPACER"
    exit 0;
fi
}

removeConfigDirectory() {
      rm -f -R "$config_file_directory"
}

validateObserveHostName () {
  local url="$1"
  # check for properly formatted url input - assumes - https://<customer-id>.collect.observe[anything]/
  # we can modify this rule to be specific as needed
  regex='^(https?)://[0-9]+.collect.observe[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*\/'


  if [[ $url =~ $regex ]]
  then
      echo "$SPACER"
      echo "$url IS valid"
      echo "$SPACER"
  else
      echo "$SPACER"
      echo "$url IS NOT valid - example valid input - https://123456789012.collect.observeinc.com/"
      echo "$SPACER"
      exit 1
  fi
}

includeFiletdAgent(){
  # Process modules
  IFS=',' read -a CONFS <<< "$module"
  for i in "${CONFS[@]}"; do
        echo "includeFiletdAgent - $i"

        case ${i} in
            linux_host)
              sudo cp "$config_file_directory/observe-linux-host.conf" /etc/td-agent-bit/observe-linux-host.conf;
              ;;
            jenkins)
              sudo cp "$config_file_directory/observe-jenkins.conf" /etc/td-agent-bit/observe-jenkins.conf;
              ;;
            *)
              echo "includeFiletdAgent function failed - i = $i"
              echo "$SPACER"
              echo "$END_OUTPUT"
              echo "$SPACER"
              exit 1;
              ;;
        esac
  done
}

setInstallFlags(){
  # Process modules
  echo "$SPACER"
  echo "setInstallFlags - module=$module"
  echo "$SPACER"

  IFS=',' read -a CONFS <<< "$module"
  for i in "${CONFS[@]}"; do
        echo "setInstallFlags - $i"

        case ${i} in
            linux_host)
            echo "setInstallFlags linux_host flags"
              osqueryinstall="TRUE"
              telegrafinstall="TRUE"
              fluentbitinstall="TRUE"
              ;;
            jenkins)
              fluentbitinstall="TRUE"
              ;;
            *)
              echo "setInstallFlags function failed - i = $i"
              echo "$SPACER"
              echo "$END_OUTPUT"
              echo "$SPACER"
              exit 1;
              ;;
        esac
  done
}

printMessage(){
  local message="$1"
  echo
  echo "$SPACER"
  echo "$message"
  echo "$SPACER"
  echo
}

SPACER=$(generateSpacer)

echo "$SPACER"
echo "Script starting ..."

echo "$SPACER"
echo "Validate inputs ..."

customer_id=0
ingest_token=0
observe_host_name_base=
config_files_clean="FALSE"
ec2metadata="FALSE"
datacenter="AWS"
testeject="NO"
appgroup="UNSET"
branch_input="main"
validate_endpoint="TRUE"
module="linux_host"
osqueryinstall="FALSE"
telegrafinstall="FALSE"
fluentbitinstall="FALSE"
observe_jenkins_path="/var/lib/jenkins/"


if [ "$1" == "--help" ]; then
  printHelp
  echo "$SPACER"
  echo "$END_OUTPUT"
  echo "$SPACER"
  exit 0
fi

if [ $# -lt 4 ]; then
  requiredInputs
fi

    # Parse inputs
    while [ $# -gt 0 ]; do
    echo "required inputs $1 $2 $# "
      case "$1" in
        --customer_id)
          customer_id="$2"
          ;;
        --ingest_token)
          ingest_token="$2"
          ;;
        --observe_host_name)
          observe_host_name_base="$2"
          ;;
        --config_files_clean)
          config_files_clean="$2"
          ;;
        --ec2metadata)
          ec2metadata="$2"
          ;;
        --datacenter)
          datacenter="$2"
          ;;
        --appgroup)
          appgroup="$2"
          ;;
        --testeject)
          testeject="$2"
          ;;
        --branch_input)
          branch_input="$2"
          ;;
        --module)
          module="$2"
          ;;
        --validate_endpoint)
          validate_endpoint="$2"
          ;;
        --observe_jenkins_path)
          observe_jenkins_path="$2"
          ;;
        *)

      esac
      shift
      shift
    done

    if [ "$customer_id" == 0 ] || [ "$ingest_token" == 0 ]; then
      requiredInputs
    fi

# Custruct the per-customer-id ingest host name.
if [ -z "$observe_host_name_base" ]; then
  observe_host_name_base="https://${customer_id}.collect.observeinc.com/"
fi

validateObserveHostName "$observe_host_name_base"

observe_host_name=$(echo "$observe_host_name_base" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

echo "$SPACER"
echo "customer_id: ${customer_id}"
echo "ingest_token: ${ingest_token}"
echo "observe_host_name_base: ${observe_host_name_base}"
echo "observe_host_name: ${observe_host_name}"
echo "config_files_clean: ${config_files_clean}"
echo "ec2metadata: ${ec2metadata}"
echo "datacenter: ${datacenter}"
echo "appgroup: ${appgroup}"
echo "testeject: ${testeject}"
echo "validate_endpoint: ${validate_endpoint}"
echo "branch_input: ${branch_input}"
echo "module: ${module}"
echo "observe_jenkins_path: ${observe_jenkins_path}"

setInstallFlags

printMessage "osqueryinstall = $osqueryinstall"
printMessage "telegrafinstall = $telegrafinstall"
printMessage "fluentbitinstall = $fluentbitinstall"


OBSERVE_ENVIRONMENT="$observe_host_name"

DEFAULT_OBSERVE_HOSTNAME="${HOSTNAME}"

DEFAULT_OBSERVE_DATA_CENTER="$datacenter"

if [ "$validate_endpoint" == TRUE ]; then

    echo "$SPACER"
    echo "Validate customer_id / ingest token ..."
    echo "$SPACER"
    echo

    curl_endpoint=$(curl https://"${OBSERVE_ENVIRONMENT}"/v1/http/script_validation \
    -H "Authorization: Bearer ${ingest_token}" \
    -H "Content-type: application/json" \
    -d "{\"data\": {  \"datacenter\": \"${DEFAULT_OBSERVE_DATA_CENTER}\",\"host\": \"${DEFAULT_OBSERVE_HOSTNAME}\",\"message\": \"validating customer id and token\", \"os\": \"${TERRAFORM_REPLACE_OS_VALUE}\", \"result\": \"SUCCESS\",  \"script_run\": \"${DEFAULT_OBSERVE_DATA_CENTER}\" ,  \"OBSERVE_TEST_RUN_KEY\": \"${OBSERVE_TEST_RUN_KEY}\"}}")

    validate_endpoint_result=$(echo "$curl_endpoint" | grep -c -Po '(?<="ok":)(true)')

    if ((validate_endpoint_result != 1 )); then
        echo "$SPACER"
        echo "Invalid value for customer_id or ingest_token"
        echo "$curl_endpoint"
        echo "$SPACER"
        echo "$END_OUTPUT"
        echo "$SPACER"
        exit 1
    else
        echo "$SPACER"
        echo "Successfully validated customer_id and ingest_token"
    fi

    echo

fi

echo "$SPACER"
echo "Values for configuration:"
echo "$SPACER"
echo "    Environment:  $OBSERVE_ENVIRONMENT"
echo
echo "    Data Center:  $DEFAULT_OBSERVE_DATA_CENTER"
echo
echo "    Hostname:  $DEFAULT_OBSERVE_HOSTNAME"
echo
echo "    Customer ID:  $customer_id"
echo
echo "    Customer Ingest Token:  $ingest_token"

testEject "${testeject}" "EJECT1"

echo "$SPACER"

getConfigurationFiles "$branch_input"

echo "$SPACER"

cd "$config_file_directory" || (exit && echo "$SPACER CONFIG FILE DIRECTORY PROBLEM - $(pwd) - $config_file_directory - $END_OUTPUT $SPACER")

sed -i "s/REPLACE_WITH_DATACENTER/${DEFAULT_OBSERVE_DATA_CENTER}/g" ./*

sed -i "s/REPLACE_WITH_HOSTNAME/${DEFAULT_OBSERVE_HOSTNAME}/g" ./*

sed -i "s/REPLACE_WITH_CUSTOMER_INGEST_TOKEN/${ingest_token}/g" ./*

sed -i "s/REPLACE_WITH_OBSERVE_ENVIRONMENT/${OBSERVE_ENVIRONMENT}/g" ./*

sed -i "s:REPLACE_WITH_OBSERVE_JENKINS_PATH:${observe_jenkins_path}:g" ./*

if [ "$ec2metadata" == TRUE ]; then
    sed -i "s/#REPLACE_WITH_OBSERVE_EC2_OPTION//g" ./*
fi

if [ "$appgroup" != UNSET ]; then
    sed -i "s/#REPLACE_WITH_OBSERVE_APP_GROUP_OPTION/Record appgroup ${appgroup}/g" ./*
fi

testEject "${testeject}" "EJECT2"

# https://docs.observeinc.com/en/latest/content/integrations/linux/linux.html



#####################################
# BASELINEINSTALL - START
#####################################

case ${OS} in
    amzn|amazonlinux)

    echo "Amazon OS"

      #####################################
      # osquery
      #####################################
      if [ "$osqueryinstall" == TRUE ]; then

        printMessage "osquery"

        curl -L https://pkg.osquery.io/rpm/GPG | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery

        sudo yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo
        sudo yum-config-manager --enable osquery-s3-rpm-repo
        sudo yum install osquery -y
        sudo service osqueryd start 2>/dev/null || true


        # ################
        sourcefilename=$config_file_directory/osquery.conf
        filename=/etc/osquery/osquery.conf


        osquery_conf_filename=/etc/osquery/osquery.conf

        if [ -f "$filename" ]
        then
            sudo mv "$filename"  "$filename".OLD
        fi

        sudo cp "$sourcefilename" "$filename"

        sourcefilename=$config_file_directory/osquery.flags
        filename=/etc/osquery/osquery.flags
        osquery_flags_filename=/etc/osquery/osquery.flags

        if [ -f "$filename" ]
        then
            sudo mv "$filename"  "$filename".OLD
        fi

        sudo cp "$sourcefilename" "$filename"

        sudo service osqueryd restart

      fi
      # #####################################
      # # fluent
      # #####################################
      if [ "$fluentbitinstall" == TRUE ]; then

      printMessage "fluent"

sudo tee /etc/yum.repos.d/td-agent-bit.repo > /dev/null << EOT
[td-agent-bit]
name = TD Agent Bit
baseurl = https://packages.fluentbit.io/amazonlinux/2/\$basearch/
gpgcheck=1
gpgkey=https://packages.fluentbit.io/fluentbit.key
enabled=1
EOT

      sudo yum install td-agent-bit -y

      sourcefilename=$config_file_directory/td-agent-bit.conf
      filename=/etc/td-agent-bit/td-agent-bit.conf

      td_agent_bit_filename=/etc/td-agent-bit/td-agent-bit.conf



      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      includeFiletdAgent

      sudo service td-agent-bit restart

    fi
      # #####################################
      # # telegraf
      # #####################################
      if [ "$telegrafinstall" == TRUE ]; then

      printMessage "telegraf"

sudo tee /etc/yum.repos.d/influxdb.repo > /dev/null << EOT
[influxdb]
name = InfluxDB Repository - RHEL
baseurl = https://repos.influxdata.com/rhel/7/\$basearch/stable/
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOT

      sudo yum install telegraf -y

      sourcefilename=$config_file_directory/telegraf.conf
      filename=/etc/telegraf/telegraf.conf

      telegraf_conf_filename=/etc/telegraf/telegraf.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      sudo service telegraf restart

    fi
      ################################################################################################
      ################################################################################################
          ;;

   ################################################################################################
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
   ################################################################################################
    # rhel|centos
    #####################################
    #####################################
    rhel|centos)
      echo "RHEL OS"
      #####################################
      # osquery
      #####################################
      if [ "$osqueryinstall" == TRUE ]; then
        printMessage "osquery"

        sudo yum install yum-utils -y

        curl -L https://pkg.osquery.io/rpm/GPG | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery

        sudo yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo

        sudo yum-config-manager --enable osquery-s3-rpm-repo

        sudo yum install osquery -y


        # ################
        sourcefilename=$config_file_directory/osquery.conf
        filename=/etc/osquery/osquery.conf

        osquery_conf_filename=/etc/osquery/osquery.conf

        if [ -f "$filename" ]
        then
            sudo mv "$filename"  "$filename".OLD
        fi

        sudo cp "$sourcefilename" "$filename"

        sourcefilename=$config_file_directory/osquery.flags
        filename=/etc/osquery/osquery.flags

        osquery_flags_filename=/etc/osquery/osquery.flags

        if [ -f "$filename" ]
        then
            sudo mv "$filename"  "$filename".OLD
        fi

        sudo cp "$sourcefilename" "$filename"

        sudo service osqueryd restart
    fi
      # #####################################
      # # fluent
      # #####################################
      if [ "$fluentbitinstall" == TRUE ]; then
      printMessage "fluent"

cat << EOF | sudo tee /etc/yum.repos.d/td-agent-bit.repo
[td-agent-bit]
name = TD Agent Bit
baseurl = https://packages.fluentbit.io/centos/\$releasever/\$basearch/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.fluentbit.io/fluentbit.key
enabled=1
EOF

      sudo yum install td-agent-bit -y

      sudo service td-agent-bit start

      sourcefilename=$config_file_directory/td-agent-bit.conf
      filename=/etc/td-agent-bit/td-agent-bit.conf

      td_agent_bit_filename=/etc/td-agent-bit/td-agent-bit.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      includeFiletdAgent

      sudo service td-agent-bit restart

    fi
      # #####################################
      # # telegraf
      # #####################################
      if [ "$telegrafinstall" == TRUE ]; then
      printMessage "telegraf"

cat << EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 0
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

      sudo yum install telegraf -y

      sourcefilename=$config_file_directory/telegraf.conf
      filename=/etc/telegraf/telegraf.conf

      telegraf_conf_filename=/etc/telegraf/telegraf.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      yum install ntp -y

      sudo service telegraf restart

    fi
      ################################################################################################
      ################################################################################################
          ;;

    ubuntu)
      echo "UBUNTU OS"
      #####################################
      # osquery
      #####################################
      if [ "$osqueryinstall" == TRUE ]; then

      printMessage "osquery"

      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B

      if ! grep -Fq https://pkg.osquery.io/deb /etc/apt/sources.list.d/osquery.list
      then
sudo tee -a /etc/apt/sources.list.d/osquery.list > /dev/null << EOT
deb [arch=amd64] https://pkg.osquery.io/deb deb main
EOT
      fi

      sudo apt-get update
      sudo apt-get install -y osquery
      sudo service osqueryd start 2>/dev/null || true

      # ################
      sourcefilename=$config_file_directory/osquery.conf
      filename=/etc/osquery/osquery.conf

      osquery_conf_filename=/etc/osquery/osquery.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      sourcefilename=$config_file_directory/osquery.flags
      filename=/etc/osquery/osquery.flags

      osquery_flags_filename=/etc/osquery/osquery.flags

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      sudo service osqueryd restart

      fi

      # #####################################
      # # fluent
      # #####################################
      if [ "$fluentbitinstall" == TRUE ]; then
      printMessage "fluent"

      wget -qO - https://packages.fluentbit.io/fluentbit.key | sudo apt-key add -

      echo deb https://packages.fluentbit.io/ubuntu/"${CODENAME}" "${CODENAME}" main | sudo tee -a /etc/apt/sources.list

      sudo apt-get update
      sudo apt-get install -y td-agent-bit
      sudo service td-agent-bit start

      sourcefilename=$config_file_directory/td-agent-bit.conf
      filename=/etc/td-agent-bit/td-agent-bit.conf

      td_agent_bit_filename=/etc/td-agent-bit/td-agent-bit.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      includeFiletdAgent

      sudo service td-agent-bit restart

    fi
      # #####################################
      # # telegraf
      # #####################################
      if [ "$telegrafinstall" == TRUE ]; then
      printMessage "telegraf"

      wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
          #shellcheck disable=SC1091
      source /etc/lsb-release
      if ! grep -Fq https://repos.influxdata.com/"${DISTRIB_ID,,}" /etc/apt/sources.list.d/influxdb.list
      then
sudo tee -a /etc/apt/sources.list.d/influxdb.list > /dev/null << EOT
deb https://repos.influxdata.com/"${DISTRIB_ID,,}" "${DISTRIB_CODENAME}" stable
EOT
      fi

      sudo apt-get update
      sudo apt-get install -y telegraf
      sudo apt-get install -y ntp

      sourcefilename=$config_file_directory/telegraf.conf
      filename=/etc/telegraf/telegraf.conf

      telegraf_conf_filename=/etc/telegraf/telegraf.conf

      if [ -f "$filename" ]
      then
          sudo mv "$filename"  "$filename".OLD
      fi

      sudo cp "$sourcefilename" "$filename"

      sudo service telegraf restart

      fi
          ;;
      ################################################################################################
      ################################################################################################
    *)
        echo "Unknown OS"
        echo "$SPACER"
        echo "$END_OUTPUT"
        echo "$SPACER"
        exit 1;
          ;;
  esac


if [ "$fluentbitinstall" == TRUE ]; then
  echo "$SPACER"
  echo "Check Services"
  echo "$SPACER"
  echo
  echo "$SPACER"
  echo "td-agent-bit status"

  if systemctl is-active --quiet td-agent-bit; then
    echo td-agent-bit is running

    curlObserve "td-agent-bit is running" "td-agent-bit" "SUCCESS"

  else
    echo td-agent-bit is NOT running

    curlObserve "td-agent-bit is NOT running" "td-agent-bit" "FAILURE"

    sudo service td-agent-bit status
  fi




  echo "$SPACER"
  echo "Check status - sudo service td-agent-bit status"
  echo "Config file location: ${td_agent_bit_filename}"
  echo

fi
echo "$SPACER"

if [ "$osqueryinstall" == TRUE ]; then
  echo "osqueryd status"

  if systemctl is-active --quiet osqueryd; then
    echo osqueryd is running

  curlObserve "osqueryd is running" "osqueryd" "SUCCESS"

  else
    echo osqueryd is NOT running

    curlObserve "osqueryd is NOT running" "osqueryd" "FAILURE"

    sudo service osqueryd status
  fi
  echo "$SPACER"
  echo "Check status - sudo service osqueryd status"

  echo "Config file location: ${osquery_conf_filename}"

  echo "Flag file location: ${osquery_flags_filename}"
  echo

fi

if [ "$telegrafinstall" == TRUE ]; then
    echo "$SPACER"
    echo "telegraf status"

    if systemctl is-active --quiet telegraf; then
      echo telegraf is running

      curlObserve "telegraf is running" "telegraf" "SUCCESS"

    else
      echo telegraf is NOT running

      curlObserve "telegraf is NOT running" "telegraf" "FAILURE"

      sudo service telegraf status
    fi
    echo "$SPACER"
    echo "Check status - sudo service telegraf status"

    echo "Config file location: ${telegraf_conf_filename}"
    echo
    echo "$SPACER"
    echo
    echo "$SPACER"
    echo "Datacenter value:  ${DEFAULT_OBSERVE_DATA_CENTER}"
fi

if [ "$config_files_clean" == TRUE ]; then
  removeConfigDirectory
fi


#####################################
# BASELINEINSTALL - END
#####################################

echo "$SPACER"
echo "$END_OUTPUT"
echo "$SPACER"
