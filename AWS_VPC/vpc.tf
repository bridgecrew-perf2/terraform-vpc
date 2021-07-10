#Provider
provider "aws" {
  region = "${var.region}"
}

#Create a VPC
resource "aws_vpc" "my-vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_support = "true"  #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink = "false"
    instance_tenancy = "default"

    tags = {
        Name = "Terraform-VPC"
    }
}

#Create Public Subnets
resource "aws_subnet" "my-public-subnet" {
    count = "${length(var.public_subnet_cidrs)}"
    vpc_id = "${aws_vpc.my-vpc.id}"
    cidr_block = "${var.public_subnet_cidrs[count.index]}"
    availability_zone = "${var.availability_zones[count.index]}"
    map_public_ip_on_launch = "true"
    tags = {
      "Name" = "Terraform-Public-Subnet-${count.index + 1}"
    }
}

#Create Internet Gateway
resource "aws_internet_gateway" "my-igw" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    tags = {
      "Name" = "Terraform-IGW"
    } 
}

#Create Custom Public Route Table
resource "aws_route_table" "my-pub-rt" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.my-igw.id}"
    }
    tags = {
      "Name" = "Terraform-Public-RT"
    }
}

# route associations public
resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnet_cidrs)}"
  subnet_id = "${element(aws_subnet.my-public-subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.my-pub-rt.id}"
}

#Create Private Subnets

resource "aws_subnet" "my-private-subnet" {
    count = "${length(var.private_subnet_cidrs)}"
    vpc_id = "${aws_vpc.my-vpc.id}"
    cidr_block = "${var.private_subnet_cidrs[count.index]}"
    availability_zone = "${var.availability_zones[count.index]}"
    map_public_ip_on_launch = "false"
    tags = {
      "Name" = "Terraform-Private-Subnet-${count.index + 1}"
    }
}

#NAT Gateway
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.my-public-subnet[count.index].id
  connectivity_type = "public"
  depends_on = [aws_internet_gateway.my-igw]  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
}

#Create Custom Private Route Table
resource "aws_route_table" "my-prv-rt" {
  vpc_id = "${aws_vpc.my-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
  }
  tags = {
    Name = "Terraform-Private-RT"
  }
}

# route associations private
resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnet_cidrs)}"
  subnet_id = "${element(aws_subnet.my-private-subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.my-prv-rt.id}"
}