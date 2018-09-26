# Configure the AWS Provider
provider "aws" {
  region     = "sa-east-1"
}

# Configure a vpc
resource "aws_vpc" "sample_vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Configure public subnet
resource "aws_subnet" "sample_public_subnet" {
  vpc_id     = "${aws_vpc.sample_vpc.id}"
  cidr_block = "172.16.0.0/24"
  availability_zone = "sa-east-1a"
  map_public_ip_on_launch = false
}

# Configure private subnet
resource "aws_subnet" "sample_private_subnet" {
  vpc_id     = "${aws_vpc.sample_vpc.id}"
  cidr_block = "172.16.1.0/24"
  availability_zone = "sa-east-1a"
}

# Configure internet gateway
resource "aws_internet_gateway" "sample_internet_gateway" {
  vpc_id = "${aws_vpc.sample_vpc.id}"
}

# Configure public route table
resource "aws_route_table" "sample_public_routetable" {
  vpc_id = "${aws_vpc.sample_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.sample_internet_gateway.id}"
  }
}

# Associate public subnet and public route table
resource "aws_route_table_association" "sample_public_subnet" {
  subnet_id      = "${aws_subnet.sample_public_subnet.id}"
  route_table_id = "${aws_route_table.sample_public_routetable.id}"
}

# Providing Elastic Ip
resource "aws_eip" "sample_nat" {
  vpc = true
}

# Creating Nat gateway
resource "aws_nat_gateway" "sample_gw" {
  allocation_id = "${aws_eip.sample_nat.id}"
  subnet_id     = "${aws_subnet.sample_public_subnet.id}"
}

# Creating private route table
resource "aws_route_table" "sample_private_routetable" {
  vpc_id = "${aws_vpc.sample_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.sample_gw.id}"
  }
}

# Associate private subnet and route table
resource "aws_route_table_association" "sample_private_subnet" {
  subnet_id      = "${aws_subnet.sample_private_subnet.id}"
  route_table_id = "${aws_route_table.sample_private_routetable.id}"
}
