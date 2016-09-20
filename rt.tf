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
