resource "aws_eip" "nat1_ip" {
  instance   = "${aws_instance.microservice_nat.id}"
  vpc        = true
  depends_on = ["aws_instance.microservice_nat"]
}
