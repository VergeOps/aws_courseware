provider "aws" {}

# ------------------------------------------
# DATA SOURCES
# ------------------------------------------

data "aws_availability_zones" "available" {}

# ------------------------------------------
# VPC
# ------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "${var.vpc_name}"
  }
}

# ------------------------------------------
# INTERNET GATEWAY
# ------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"

  tags {
    Name = "${var.vpc_name}-ig"
  }
}

# ------------------------------------------
# PUBLIC SUBNETS
#
# Create a subnet for every AZ.
# ------------------------------------------

resource "aws_subnet" "public" {
  count = "${length(data.aws_availability_zones.available.names)}"

  vpc_id                  = "${aws_vpc.this.id}"
  cidr_block              = "${element(var.public_subnet_cidrs, count.index)}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.vpc_name}-public-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

# ------------------------------------------
# ROUTE TABLE FOR PUBLIC SUBNETS
#
# Add a public gateway to the public route table and associate the two public subnets.
# ------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.this.id}"

  tags {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route" "public" {
  depends_on             = ["aws_route_table.public"]
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"
}

resource "aws_route_table_association" "public" {
  depends_on = ["aws_subnet.public"]
  count      = "${aws_subnet.public.count}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

# ------------------------------------------
# PRIVATE APP SUBNETS
#
# Create an Application subnet for every AZ.
# ------------------------------------------

resource "aws_subnet" "private_app" {
  count = "${length(data.aws_availability_zones.available.names)}"

  vpc_id                  = "${aws_vpc.this.id}"
  cidr_block              = "${element(var.private_app_subnet_cidrs, count.index)}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.vpc_name}-private-app-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}


# ------------------------------------------
# ROUTE TABLE FOR PRIVATE SUBNETS
#
# Add a the NAT gateway to the private route table and associate the two private subnets.
# ------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.this.id}"

  tags {
    Name = "${var.vpc_name}-private-rt"
  }
}

resource "aws_route" "private" {
  depends_on             = ["aws_route_table.private"]
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.this.id}"
}

resource "aws_route_table_association" "private_app" {
  count      = "${aws_subnet.private_app.count}"

  subnet_id      = "${element(aws_subnet.private_app.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}


# ------------------------------------------
# NAT GATEWAY
#
# Includes the required creation of an Elastic IP.
# ------------------------------------------

resource "aws_eip" "this" {
  vpc = true
}

resource "aws_nat_gateway" "this" {
  allocation_id = "${aws_eip.this.id}"
  subnet_id     = "${aws_subnet.public.0.id}"

  tags {
    Name = "${var.vpc_name}-ngw"
  }
}
