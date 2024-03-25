# FOR OBSERVE INTERNAL USERS 

## Terraform AWS Sample Infrastructure
Clone or download this repository to your local machine

Assumptions - you have docker desktop installed

Within this directory the terraform folder provides a sample deployment for Linux and Windows with otel collector installed and pushing data to your Observe environment.

You will need:
- observe_collection_endpoint - example "https://REPLACE_WITH_YOUR_CUSTOMER_ID.collect.observe.com" 
- observe_token "REPLACE_WITH_DATASTREAM_TOKEN"

### Create an auto vars file for terraform to read

You will need to create a file for providing variables to terraform.  Use the following commands within the ***terraform*** directory.  
Be sure to replace OBSERVE_ENDPOINT and OBSERVE_TOKEN with your values:

```
touch observe_vars.auto.tfvars

cat <<EOF > observe_vars.auto.tfvars
name_format      = "host-explorer-test-%s"
OBSERVE_ENDPOINT = "https://[123456789].collect.[observe-staging].com"
OBSERVE_CUSTOMER_DOMAIN = = "[123456789].observe-staging.com"
OBSERVE_TOKEN_OTEL    = "[gobbly:gook]"
OBSERVE_TOKEN_HOST_MONITORING    = "[gobbly:gook]"
OBSERVE_CUSTOMER = "[123456789]"
EOF
```

For simplicity I have assumed you have docker desktop installed and therefore can run terraform with the below commands.

To pull image from DockerHub:
```
docker pull hashicorp/terraform:1.6
```

[Login to Britive using script](../../aws_helper/SETUP_README.md)

Look at test_machines local variable in variables.tf file for a list of machines you can create.  Comment out as needed.

To run terraform init - notice the mapping of volumes(-v) and environment variables (-e)
```
docker run -i -t \
-v $(pwd)/:/workspace \
-v $HOME/.aws:/aws_creds \
-e AWS_SHARED_CREDENTIALS_FILE=/aws_creds/credentials \
-e AWS_PROFILE=dce -w /workspace \
-e AWS_REGION=us-west-2 \
hashicorp/terraform:1.6 \
init
```

To create the ec2 instances within an ephemeral account run the following:
```
docker run -i -t \
-v $(pwd)/:/workspace \
-v $HOME/.aws:/aws_creds \
-e AWS_SHARED_CREDENTIALS_FILE=/aws_creds/credentials \
-e AWS_PROFILE=dce -w /workspace \
-e AWS_REGION=us-west-2 \
hashicorp/terraform:1.6 \
apply -auto-approve;
```

To see what terraform will do run a plan:
```
docker run -i -t \
-v $(pwd)/:/workspace \
-v $HOME/.aws:/aws_creds \
-e AWS_SHARED_CREDENTIALS_FILE=/aws_creds/credentials \
-e AWS_PROFILE=dce -w /workspace \
-e AWS_REGION=us-west-2 \
hashicorp/terraform:1.6 \
plan
```

After the create process is completed you should start to see data flowing to your Observe account.

To delete the ec2 instances within an ephemeral account run the following:
```
docker run -i -t \
-v $(pwd)/:/workspace \
-v $HOME/.aws:/aws_creds \
-e AWS_SHARED_CREDENTIALS_FILE=/aws_creds/credentials \
-e AWS_PROFILE=dce -w /workspace \
-e AWS_REGION=us-west-2 \
hashicorp/terraform:1.6 \
destroy -auto-approve
```

Destroy and Create

```
docker run -i -t \
-v $(pwd)/:/workspace \
-v $HOME/.aws:/aws_creds \
-e AWS_SHARED_CREDENTIALS_FILE=/aws_creds/credentials \
-e AWS_PROFILE=dce -w /workspace \
-e AWS_REGION=us-west-2 \
hashicorp/terraform:1.6 \
destroy -auto-approve;
docker run -i -t \
-v $(pwd)/:/workspace \
-v $HOME/.aws:/aws_creds \
-e AWS_SHARED_CREDENTIALS_FILE=/aws_creds/credentials \
-e AWS_PROFILE=dce -w /workspace \
-e AWS_REGION=us-west-2 \
hashicorp/terraform:1.6 \
apply -auto-approve;
```

If you have terraform installed locally - and you don't want to use docker - then run 
```
export AWS_PROFILE=dce; export AWS_REGION=us-west-2 before running terraform commands.
```

## Other commands you run (replace destroy -auto-approve above ^^^^^^ )
```
plan

output -json | jq -cr '.hosts_aws.value'

```

Terraform will create ephemeral key files for you that you can use to log in to your vm.  You should see a list of vms created in outputs when apply is complete that look like this:
```
    "host-explorer-test-otel_0-UBUNTU_20_04_LTS_MKjlCd" = {
      "host" = "34.209.148.230"
      "instance_id" = "i-063135d0980a0120f"
      "machine" = "AWS_UBUNTU_20_04_LTS"
      "public_ssh_link" = "ssh -i keypair_module/keys/ephemeral_key ubuntu@34.209.148.230"
      "sleep" = 120
      "user" = "ubuntu"
  }
```
If you want to login to your vm for any reason use the public_ssh_link value to ssh to your machine.

Following assumes you have jq installed:
```
brew install jq
```
To get a list of outputs at any time use the following command:
```
docker run -i -t \
-v $(pwd)/:/workspace \
-v $HOME/.aws:/aws_creds \
-e AWS_SHARED_CREDENTIALS_FILE=/aws_creds/credentials \
-e AWS_PROFILE=dce -w /workspace \
-e AWS_REGION=us-west-2 \
hashicorp/terraform:1.6 \
output -json | jq -cr '.hosts_aws.value'
```


# References
### Setup Britive
https://www.notion.so/observeinc/How-to-Use-Britive-Access-Management-36393b713cbf41ada73a846ddabfea21?pvs=4#e51bfe23dc8a4dc3a8e51aaeda4ee4fe


### create an ephemeral account - you will need dce utility
[Setup dce](https://dce.readthedocs.io/en/latest/howto.html)

systemctl --type=service --state=running


while IFS= read -r line; do
    echo "Processing line: $line"
    # Perform actions on each line here
    tf taint $line
done < <(tf state list | grep linux)