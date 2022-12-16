

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  provider         = aws.thunderdome
  instance_tenancy = "default"
  tags = merge(
    var.BASE_TAGS,
    { Name = format(var.name_format, "vpc") },
  )
}

resource "aws_internet_gateway" "IGW" { # Creating Internet Gateway
  vpc_id   = aws_vpc.main.id            # vpc_id will be generated after we create VPC
  provider = aws.thunderdome
}

resource "aws_route_table" "PublicRT" { # Creating RT for Public Subnet
  vpc_id   = aws_vpc.main.id
  provider = aws.thunderdome
  route {
    cidr_block = "0.0.0.0/0" # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.IGW.id
  }
}

resource "aws_route_table_association" "PublicRTassociation" {
  provider       = aws.thunderdome
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.PublicRT.id
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  provider   = aws.thunderdome

  tags = merge(
    var.BASE_TAGS,
    { Name = format(var.name_format, "subnet") }
  )
}

