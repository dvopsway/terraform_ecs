resource "aws_network_acl" "location-private" {
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
    "Name" = "location-private"
  }
}
