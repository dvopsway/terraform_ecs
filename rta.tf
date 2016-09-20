resource "aws_route_table_association" "microservice_public_rtbassoc" {
  route_table_id = "${aws_route_table.microservice_publicrtb.id}"
  subnet_id      = "${element(aws_subnet.microservice_publicsubnet.*.id, count.index)}"
  count          = 2
}

resource "aws_route_table_association" "microservice_private_rtbassoc" {
  route_table_id = "${aws_route_table.microservice_privatertb.id}"
  subnet_id      = "${element(aws_subnet.microservice_privatesubnet.*.id, count.index)}"
  count          = 2
}
