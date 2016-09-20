resource "aws_instance" "microservice_nat" {
  ami                    = "${var.nat_ami}"
  ebs_optimized          = false
  instance_type          = "t2.micro"
  monitoring             = true
  key_name               = "${var.keyname}"
  subnet_id              = "${aws_subnet.microservice_publicsubnet.0.id}"
  vpc_security_group_ids = ["${aws_security_group.microservice_nat_sg.id}"]
  source_dest_check      = false

  tags {
    "Name" = "nat01.${var.microservice_name}"
  }
}
