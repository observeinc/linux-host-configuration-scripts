#!/bin/bash
# Run this to make executable - # chmod u=rwx,g=rx,o=r configure_script.sh

cd ~ || exit

mkdir config_files

# shellcheck disable=SC2154 #input dynamically set by terraform
getFiles(){
    # shellcheck disable=SC2034 #value in string TERRAFORM_REPLACE_GITHUB_CURL_COMMANDS
    local branch_replace="$1"
    rm "config_files/*"
    curl https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/"$branch_replace"/script_files/RHEL_8_4_0/osquery.conf > config_files/osquery.conf
curl https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/"$branch_replace"/script_files/RHEL_8_4_0/osquery.flags > config_files/osquery.flags
curl https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/"$branch_replace"/script_files/RHEL_8_4_0/telegraf.conf > config_files/telegraf.conf
curl https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/"$branch_replace"/script_files/RHEL_8_4_0/td-agent-bit.conf > config_files/td-agent-bit.conf

}

# shellcheck disable=SC2154 #input dynamically set by terraform
#!/bin/bash

generateTestKey(){
echo "${OBSERVE_TEST_RUN_KEY}"
}

# AWS metadata IP: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html

# generateHostName(){
# local environment_input="$1"
# # future use in case we want to set a value for testing
# if [[ "$environment_input" == *"STAGE"* ]]; then
#   curl -s http://169.254.169.254/latest/meta-data/hostname
# else
#   curl -s http://169.254.169.254/latest/meta-data/hostname
# fi
# }

# generateDatacenter(){
# local environment_input="$1"
# # if stage concatenates a testing key with AWS datacenter value
# if [[ "$environment_input" == *"STAGE"* ]]; then
#   x=$(generateTestKey); 
#   y=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone); 
#   z="${x}_${y}"; 
#   echo "$z";
# else
#   curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone
# fi
# }

# pick endpoint based on environment
# generateEnvironmentString(){
# local environment_input="$1"
# if [[ "$environment_input" == "PROD" ]]; then
#   echo "collect.observeinc.com"
# else
#   echo "collect.observe-staging.com"
# fi
# }

# used for terminal output
generateSpacer(){
  echo "###########################################"
}

curlObserve(){
  local message="$1"
  local path_suffix="$2"
  local result="$3"
   # shellcheck disable=SC2154 #set in upstream script
  curl https://"${OBSERVE_ENVIRONMENT}"/v1/http/script_validation/"${path_suffix}" \
  -H "Authorization: Bearer ${customer_id} ${ingest_token}" \
  -H "Content-type: application/json" \
  -d "{\"data\": {\"datacenter\": \"${DEFAULT_OBSERVE_DATA_CENTER}\", \"host\": \"${DEFAULT_OBSERVE_HOSTNAME}\",\"result\": \"${result}\",\"message\": \"${message}\", \"os\": \"${TERRAFORM_REPLACE_OS_VALUE}\" }}"

}

help(){
      printf "Required inputs\n"
      printf "Required --customer_id YOUR_CUSTOMERID \n"
      printf "Required --ingest_token YOUR_DATA_STREAM_TOKEN\n\n"
      printf "Optional inputs\n"
      printf "Optional --observe_host_name PROD or STAGE - Defaults to PROD \n"
      printf "Optional --config_files_clean TRUE or FALSE - Defaults to FALSE \n"
      printf "    controls whether to delete created config_files temp directory\n"
      printf "Optional --ec2metadata TRUE or FALSE - Defaults to FALSE \n"
      printf "    controls fluentbit config for whether to use default ec2 metrics \n"
      printf "Optional --datacenter defaults to AWS\n"
      printf "Optional --appgroup id supplied sets value in fluentbit config\n"
      printf "***************************\n"
      printf " Sample command:\n"
      printf "./observe_configure_script.sh --customer_id YOUR_CUSTOMERID --ingest_token YOUR_DATA_STREAM_TOKEN --observe_host_name collect.observe-staging.com --config_files_clean TRUE --ec2metadata TRUE --datacenter MYDATACENTER --appgroup MYAPPGROUP
      
      \n"
      printf "--config_files_clean TRUE --ec2metadata TRUE --datacenter myCompanyDataCenter --appgroup myAppGroup\n"
      printf "***************************\n"
}

requiredInputs(){
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      printVars
      help
      exit 1

}

# shellcheck disable=SC2154 #set in downstream script
printVars(){
      printf "***************************\n"
      printf "* VARIABLEs *\n"
      printf "***************************\n"
      echo "customer_id: ${customer_id}"
      echo "ingest_token: ${ingest_token}"
      echo "observe_host_name: ${observe_host_name}"
      echo "config_files_clean: ${config_files_clean}"
      echo "ec2metadata: ${ec2metadata}"
      echo "datacenter: ${datacenter}"
      echo "appgroup: ${appgroup}"
      echo "testeject: ${testeject}"
      printf "***************************\n"
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
    echo "$SPACER"
    exit 0;
fi
}

removeConfigDirectory() {
      rm -f -R config_path
}

SPACER=$(generateSpacer)

echo "$SPACER"
echo "Script starting ..."

# shellcheck disable=SC2154 #input dynamically set by terraform
#!/bin/bash

echo "$SPACER"
echo "Validate inputs ..."

customer_id=0
ingest_token=0
observe_host_name="collect.observeinc.com"
config_files_clean="FALSE"
ec2metadata="FALSE"
datacenter="AWS"
testeject="NO"
appgroup="UNSET"
branch_input="main"

if [ "$1" == "--help" ]; then
echo "$SPACER"
echo "Help - "
echo "$SPACER"
  help
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
          observe_host_name="$2"
          ;;
        --config_files_clean)
        # shellcheck disable=SC2034 #used in downstream script
          config_files_clean="$2"
          ;;
        --ec2metadata)
        # shellcheck disable=SC2034 #used in downstream script
          ec2metadata="$2"
          ;;
        --datacenter)
        # shellcheck disable=SC2034 #used in downstream script
          datacenter="$2"
          ;;
        --appgroup)
        # shellcheck disable=SC2034 #used in downstream script
          appgroup="$2"
          ;;
        --testeject)
        # shellcheck disable=SC2034 #used in downstream script
          testeject="$2"
          ;;
        --branch_input)
        # shellcheck disable=SC2034 #used in downstream script
          branch_input="$2"
          ;;
        *)
          
      esac
      shift
      shift
    done

    if [ "$customer_id" == 0 ] || [ "$ingest_token" == 0 ]; then
      requiredInputs
    fi





echo "$SPACER"
echo "customer_id: ${customer_id}"
echo "ingest_token: ${ingest_token}"
echo "observe_host_name: ${observe_host_name}"
echo "config_files_clean: ${config_files_clean}"
echo "ec2metadata: ${ec2metadata}"
echo "datacenter: ${datacenter}"
echo "appgroup: ${appgroup}"
echo "testeject: ${testeject}"

echo "$SPACER"
echo "Validate customer_id / ingest token ..."
echo "$SPACER"
echo

OBSERVE_ENVIRONMENT="$observe_host_name"

DEFAULT_OBSERVE_HOSTNAME="${HOSTNAME}"

DEFAULT_OBSERVE_DATA_CENTER="$datacenter"

curl_endpoint=$(curl https://"${OBSERVE_ENVIRONMENT}"/v1/http/script_validation \
-H "Authorization: Bearer ${customer_id} ${ingest_token}" \
-H "Content-type: application/json" \
-d "{\"data\": {  \"datacenter\": \"${DEFAULT_OBSERVE_DATA_CENTER}\",\"host\": \"${DEFAULT_OBSERVE_HOSTNAME}\",\"message\": \"validating customer id and token\", \"os\": \"${TERRAFORM_REPLACE_OS_VALUE}\", \"result\": \"SUCCESS\",  \"script_run\": \"${DEFAULT_OBSERVE_DATA_CENTER}\" ,  \"OBSERVE_TEST_RUN_KEY\": \"${OBSERVE_TEST_RUN_KEY}\"}}")

 validate_endpoint=$(echo "$curl_endpoint" | grep -c -Po '(?<="ok":)(true)')

if ((validate_endpoint != 1 )); then
    echo "$SPACER"
    echo "Invalid value for customer_id or ingest_token"
    echo "$curl_endpoint"
    exit 1
fi

echo


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

# shellcheck disable=SC2154 #input dynamically set by terraform
getFiles "$branch_input"

# shellcheck disable=SC2154 #set by input
testEject "${testeject}" "EJECT2"

echo "$SPACER"

cd config_files || exit

# shellcheck disable=SC2154 #input dynamically set by terraform
#!/bin/bash

sed -i "s/REPLACE_WITH_DATACENTER/${DEFAULT_OBSERVE_DATA_CENTER}/g" ./*
sed -i "s/REPLACE_WITH_HOSTNAME/${DEFAULT_OBSERVE_HOSTNAME}/g" ./*
# shellcheck disable=SC2154 #used in downstream script
sed -i "s/REPLACE_WITH_CUSTOMER_ID/${customer_id}/g" ./*
# shellcheck disable=SC2154 #used in downstream script
sed -i "s/REPLACE_WITH_CUSTOMER_INGEST_TOKEN/${ingest_token}/g" ./*
sed -i "s/REPLACE_WITH_OBSERVE_ENVIRONMENT/${OBSERVE_ENVIRONMENT}/g" ./*

# shellcheck disable=SC2154 #used in downstream script
if [ "$ec2metadata" == TRUE ]; then
read -r -d '' AWS_EC2 <<'EOF'
[FILTER]
   Name aws
   Match *
   imds_version v1
   az true
   ec2_instance_id true
   ec2_instance_type true
   account_id true
   hostname true
   vpc_id true
EOF
else 
# shellcheck disable=SC2154 #used in downstream script
    AWS_EC2=""
fi

echo "AWS_EC2: ${AWS_EC2}"

sed -i "s/REPLACE_WITH_OBSERVE_EC2_OPTION/r $AWS_EC2/g" ./*

# shellcheck disable=SC2154 #used in downstream script
if [ "$appgroup" != "UNSET" ]; then
read -r -d '' APP_GRP <<'EOF'
Record appgroup $appgroup
EOF
else 
# shellcheck disable=SC2154 #used in downstream script
    APP_GRP=""
fi

echo "APP_GRP: ${APP_GRP}"

sed -i "s/REPLACE_WITH_OBSERVE_APP_GROUP_OPTION/r $APP_GRP/g" ./*

# shellcheck disable=SC2154 #input dynamically set by terraform
config_path=/home/"ec2-user"/config_files
# https://docs.observeinc.com/en/latest/content/integrations/linux/linux.html
#####################################
# osquery
#####################################
echo 
echo "$SPACER"
echo "osquery"
echo "$SPACER"
echo 
sudo yum install yum-utils -y

curl -L https://pkg.osquery.io/rpm/GPG | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery

sudo yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo

sudo yum-config-manager --enable osquery-s3-rpm-repo

sudo yum install osquery -y


# ################
sourcefilename=$config_path/osquery.conf
filename=/etc/osquery/osquery.conf
# shellcheck disable=SC2034 #used downstream by input dynamically set by terraform
osquery_conf_filename=/etc/osquery/osquery.conf

if [ -f "$filename" ]
then
    sudo mv "$filename"  "$filename".OLD
fi

sudo cp "$sourcefilename" "$filename"

sourcefilename=$config_path/osquery.flags
filename=/etc/osquery/osquery.flags
# shellcheck disable=SC2034 #used downstream by input dynamically set by terraform
osquery_flags_filename=/etc/osquery/osquery.flags

if [ -f "$filename" ]
then
    sudo mv "$filename"  "$filename".OLD
fi

sudo cp "$sourcefilename" "$filename"

sudo service osqueryd restart

# #####################################
# # fluent
# #####################################
echo 
echo "$SPACER"
echo "fluent"
echo "$SPACER"
echo 
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

sourcefilename=$config_path/td-agent-bit.conf
filename=/etc/td-agent-bit/td-agent-bit.conf
# shellcheck disable=SC2034 #used downstream by input dynamically set by terraform
td_agent_bit_filename=/etc/td-agent-bit/td-agent-bit.conf

if [ -f "$filename" ]
then
    sudo mv "$filename"  "$filename".OLD
fi

sudo cp "$sourcefilename" "$filename"

sudo service td-agent-bit restart

# #####################################
# # telegraf
# #####################################
echo 
echo "$SPACER"
echo "telegraf"
echo "$SPACER"
echo 
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 0
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

sudo yum install telegraf -y

sourcefilename=$config_path/telegraf.conf
filename=/etc/telegraf/telegraf.conf
# shellcheck disable=SC2034 #used downstream by input dynamically set by terraform
telegraf_conf_filename=/etc/telegraf/telegraf.conf

if [ -f "$filename" ]
then
    sudo mv "$filename"  "$filename".OLD
fi

sudo cp "$sourcefilename" "$filename"

yum install ntp -y

sudo service telegraf restart
# shellcheck disable=SC2154 #input dynamically set by terraform
#!/bin/bash

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
# shellcheck disable=SC2154 #used in downstream script
echo "Config file location: ${td_agent_bit_filename}"
echo 

echo "$SPACER"

echo "osqueryd status"

if systemctl is-active --quiet osqueryd; then
  echo osqueryd is running

curlObserve "osqueryd is running" "osqueryd" "SUCCESS"

else
  echo osqueryd is NOT running

  curlObserve "osqueryd is NOT running" "osqueryd" "FAILURE"

  # shellcheck disable=SC2046,SC2005 #hangs script if not echoed
  echo $(sudo service osqueryd status)
fi 
echo "$SPACER"
echo "Check status - sudo service osqueryd status"
# shellcheck disable=SC2154 #used in downstream script
echo "Config file location: ${osquery_conf_filename}"
# shellcheck disable=SC2154 #used in downstream script
echo "Flag file location: ${osquery_flag_filename}"
echo 

echo "$SPACER"
echo "telegraf status"

if systemctl is-active --quiet telegraf; then
  echo telegraf is running

  curlObserve "telegraf is running" "telegraf" "SUCCESS"

else
  echo telegraf is NOT running

  curlObserve "telegraf is NOT running" "telegraf" "FAILURE"

  # shellcheck disable=SC2046,SC2005 #hangs script if not echoed
  echo $(sudo service telegraf status)
fi 
echo "$SPACER"
echo "Check status - sudo service telegraf status"
# shellcheck disable=SC2154 #set in upstream script
echo "Config file location: ${telegraf_conf_filename}"
echo 
echo "$SPACER"
echo 
echo "$SPACER"
echo "Datacenter value:  ${DEFAULT_OBSERVE_DATA_CENTER}"

# shellcheck disable=SC2154 #set in upstream script
if [ "$config_files_clean" == TRUE ]; then
  removeConfigDirectory
fi