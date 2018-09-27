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

# Security group for the instances over SSH and HTTP
resource "aws_security_group" "sample_sg_web" {
  vpc_id      = "${aws_vpc.sample_vpc.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.sample_private_subnet.cidr_block}"]
  }
}

# Create web instance on public subnet
resource "aws_instance" "web" {
  ami           = "ami-0ad7b0031d41ed4b9"
  instance_type = "t2.micro"
  key_name = "sample-key"
  vpc_security_group_ids = ["${aws_security_group.sample_sg_web.id}"]
  subnet_id = "${aws_subnet.sample_public_subnet.id}"
  associate_public_ip_address = "true"
}

# Security group for the instances over SSH and HTTP
resource "aws_security_group" "sample_sg_db" {
  vpc_id      = "${aws_vpc.sample_vpc.id}"

  # SSH access from ip range
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.sample_sg_web.id}"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access for software updates
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create db instance on private subnet
resource "aws_instance" "db" {
  ami           = "ami-0ad7b0031d41ed4b9"
  instance_type = "t2.micro"
  key_name = "sample-key"
  vpc_security_group_ids = ["${aws_security_group.sample_sg_db.id}"]
  subnet_id = "${aws_subnet.sample_private_subnet.id}"
  source_dest_check = false
}
