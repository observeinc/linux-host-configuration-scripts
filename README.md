# Configuraton script for Linux
## Assumptions:
- Assumes user running script can use passwordless sudo

## What does it do
- Creates a config_files directory in home of logged in user

- Downloads configuration files from this git repository

- Installs osquery, fluentbit and telegraf

- Subsitutes values for data center, hostname, customer id, data ingest token and observe endpoint in configuration files

- Copies files to respective agent locations, renames existing files with suffix OLD

- Outputs status of services


## Steps to configure

1. Login to machine via ssh

2. Run script with flag values set

Run --help command for list of flags and options

``` curl "https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/main/observe_configure_script.sh"  | bash -s -- --help ```

###########################################
## HELP CONTENT
###########################################
### Required inputs
- Required --customer_id YOUR_OBSERVE_CUSTOMERID
- Required --ingest_token YOUR_OBSERVE_DATA_STREAM_TOKEN
## Optional inputs
- Optional --observe_host_name - Defaults to https://collect.observe.com/
- Optional --config_files_clean TRUE or FALSE - Defaults to FALSE
    - controls whether to delete created config_files temp directory
- Optional --ec2metadata TRUE or FALSE - Defaults to FALSE
    - controls fluentbit config for whether to use default ec2 metrics
- Optional --datacenter defaults to AWS
- Optional --appgroup id supplied sets value in fluentbit config
- Optional --branch_input branch of repository to pull scrips and config files from -Defaults to main
- Optional --validate_endpoint of observe_hostname using customer_id and ingest_token -Defaults to TRUE
- Optional --module to use for installs -Defaults to linux_host which installs osquery, fluentbit and telegraf
    can be combined with jenkins flag which add a config to fluentbit or only jenkons flag which only installs fluent bit with configs
- Optional --observe_jenkins_path used in combination with jenkins module - location of jenkins logs
***************************
### Sample command:
``` curl "https://raw.githubusercontent.com/observeinc/linux-host-configuration-scripts/main/observe_configure_script.sh"  | bash -s -- --customer_id YOUR_CUSTOMERID --ingest_token YOUR_DATA_STREAM_TOKEN --observe_host_name https://collect.observeinc.com/ --config_files_clean TRUE --ec2metadata TRUE --datacenter MY_DATA_CENTER --appgroup MY_APP_GROUP```
***************************
