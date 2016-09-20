# In case of internal elb uncomment the below

/*resource "aws_elb" "microservice" {
  name    = "${var.microservice_name}-internal"
  subnets = ["${aws_subnet.microservice_privatesubnet.0.id}", "${aws_subnet.microservice_privatesubnet.1.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  security_groups             = ["${aws_security_group.microservice_internal_sg.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  internal                    = true

  tags {
    Name = "${var.microservice_name}-internal"
  }
}*/

resource "aws_elb" "microservice_public" {
  name    = "${var.microservice_name}-public"
  subnets = ["${aws_subnet.microservice_publicsubnet.0.id}", "${aws_subnet.microservice_publicsubnet.1.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  security_groups             = ["${aws_security_group.microservice-elb.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "${var.microservice_name}-public"
  }
}
