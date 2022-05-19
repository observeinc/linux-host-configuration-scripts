# Configuraton script for UBUNTU_20_04_LTS

## What does it do
Inputs: 
Assumes existence of environment variables
--customer_id $OBSERVE_CUSTOMER_ID 
--ingest_token $OBSERVE_DATASTREAM_TOKEN 
STAGE for testing PROD for production
--environment_label STAGE

- Creates a config_files directory in home of logged in user

- Downloads configuration files from this git repository

- Installs osquery, fluentbit and telegraf

- Subsitutes values for data center, hostname, customer id, data ingest token and observe endpoint in configuration files

- Copies files to respective agent locations, renames existing files with suffix OLD

- Outputs status of services


## Steps to configure

1. Login to machine via ssh

1. Script flags
    * --customer_id = your observe customer id - REQUIRED
    * --ingest_token = your data stream ingest token from ui - REQUIRED
    * --observe_host_name = host endpoint used in config files - OPTIONAL - defaults to collect.observeinc.com
    * --config_files_clean = TRUE/FALSE whether to delete directory created for downloading config files - OPTIONAL - defaults to FALSE
    * --ec2metadata = TRUE/FALSE whether to add ec2 filter section to td-agent-bit.conf file - OPTIONAL - defaults to FALSE
        ```
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
        ```
    * --datacenter = value to use for datacenter in td-agent-bit.conf and telegraf.conf files - OPTIONAL - defaults to AWS
    * --appgroup = value to use for appgroup record in td-agent-bit.conf file  - OPTIONAL - defaults to null




1. Run following script
```
curl "https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts//script_files/UBUNTU_20_04_LTS/observe_configure_script.sh"  | bash -s -- --customer_id "YOUR_CUSTOMERID" --ingest_token "YOUR_DATA_STREAM_TOKEN" --observe_host_name "collect.observeinc.com" --config_files_clean TRUE --ec2metadata TRUE --datacenter "MYDATACENTER" --appgroup "MYAPPGROUP"


```