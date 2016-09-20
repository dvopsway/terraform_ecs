resource "aws_internet_gateway" "microservice_igw" {
  vpc_id = "${aws_vpc.microservice_vpc.id}"

  tags {
    "Name" = "${var.microservice_name}-igw"
  }
}
