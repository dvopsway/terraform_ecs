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
