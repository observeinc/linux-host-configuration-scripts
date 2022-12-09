# This gets your local machine ip for use in security group 
data "http" "myip" {
  url = "https://ipv4.icanhazip.com/?4"
}

# Use a pre-deployed vpc - this is where ec2 instance will be deployed
data "aws_vpc" "main" {
  default = false
  tags = {
    Name = "linux-host-test-vpc"
  }
}

data "aws_subnet" "main" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = ["linux-host-test-subnet"]
  }
}

// The Canonical User ID data source allows access to the canonical user ID for the effective account in which Terraform is working.
data "aws_canonical_user_id" "current_user" {
}

locals {

  test_key_value = {
    for key, value in random_string.output : key => "${key}_${value.id}"
  }

}

# # rando value for filtering output and validating results
resource "random_string" "output" {
  for_each = local.machine_loop
  length   = 6
  special  = false
  # keepers = {
  #   # Generate a new id each time script files change from linux_host_script
  #   output = var.script_hash[each.key]
  # }
}
