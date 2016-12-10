/**
 * VPC for microservices
 * The CIDR is picked from variables
 */
resource "aws_vpc" "microservice_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags {
    "Name" = "${var.microservice_name}"
  }
}

/**
 * Subnets:: Public Subnet
 */
resource "aws_subnet" "microservice_publicsubnet" {
  vpc_id                  = "${aws_vpc.microservice_vpc.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 2, count.index)}"
  availability_zone       = "${lookup(var.az,"zone${count.index + 1}")}"
  map_public_ip_on_launch = false
  count                   = 2

  tags {
    "Name" = "${var.microservice_name}-${lookup(var.az,"zone${count.index + 1}")}-public"
  }
}

/**
 * Subnets:: Private Subnet
 */
resource "aws_subnet" "microservice_privatesubnet" {
  vpc_id                  = "${aws_vpc.microservice_vpc.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 2, count.index + 2)}"
  availability_zone       = "${lookup(var.az,"zone${count.index + 1}")}"
  map_public_ip_on_launch = false
  count                   = 2

  tags {
    "Name" = "${var.microservice_name}-${lookup(var.az,"zone${count.index + 1}")}-private"
  }
}

/**
 * Network ACL for microservices
 */
resource "aws_network_acl" "microservice-private" {
  vpc_id     = "${aws_vpc.microservice_vpc.id}"
  subnet_ids = ["${aws_subnet.microservice_privatesubnet.0.id}", "${aws_subnet.microservice_privatesubnet.1.id}"]

  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 1
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags {
    "Name" = "microservice-private"
  }
}

/**
 * Internet Gateway for public access
 */
resource "aws_internet_gateway" "microservice_igw" {
  vpc_id = "${aws_vpc.microservice_vpc.id}"

  tags {
    "Name" = "${var.microservice_name}-igw"
  }
}

/**
 * Public Routes for Microservice
 * route through Internet gateway
 */
resource "aws_route_table" "microservice_publicrtb" {
  vpc_id = "${aws_vpc.microservice_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.microservice_igw.id}"
  }

  tags {
    "Name" = "${var.microservice_name}-publicrtb"
  }
}

/**
 * Private Routes for Microservice
 * route through NAT instance
 */
resource "aws_route_table" "microservice_privatertb" {
  vpc_id = "${aws_vpc.microservice_vpc.id}"

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${aws_instance.microservice_nat.id}"
  }

  tags {
    "Name" = "${var.microservice_name}-privatertb"
  }
}

/**
 * Route table associations for Internet traffic
 */
resource "aws_route_table_association" "microservice_public_rtbassoc" {
  route_table_id = "${aws_route_table.microservice_publicrtb.id}"
  subnet_id      = "${element(aws_subnet.microservice_publicsubnet.*.id, count.index)}"
  count          = 2
}

/**
 * Route table associations for local traffic within VPC
 */
resource "aws_route_table_association" "microservice_private_rtbassoc" {
  route_table_id = "${aws_route_table.microservice_privatertb.id}"
  subnet_id      = "${element(aws_subnet.microservice_privatesubnet.*.id, count.index)}"
  count          = 2
}
