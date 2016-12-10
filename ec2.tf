/**
 * The NAT instance for microservices
 */
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

/**
 * The security group for the NAT instance
 */
resource "aws_security_group" "microservice_nat_sg" {
  name        = "${var.microservice_name}-nat"
  description = "${var.microservice_name}-nat"
  vpc_id      = "${aws_vpc.microservice_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  /**
   * Uncomment this block if you need to be able to SSH
   * from the Internet
   */
#  ingress {
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Name" = "${var.microservice_name}-nat-sg"
  }
}

/**
 * Security group for microservice instances
 */
resource "aws_security_group" "microservice_ecs" {
  name        = "${var.microservice_name}-ecs"
  description = "${var.microservice_name}-ecs"
  vpc_id      = "${aws_vpc.microservice_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Name" = "${var.microservice_name}-ecs_instance"
  }
}


resource "aws_security_group" "microservice_internal_sg" {
  name        = "${var.microservice_name}-internal"
  description = "${var.microservice_name}-internal"
  vpc_id      = "${aws_vpc.microservice_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Name" = "${var.microservice_name}-internal"
  }
}

/**
 * Security group for the elastic load balancer
 * for public access.
 */
resource "aws_security_group" "microservice-elb" {
  name        = "microservice-elb"
  description = "microservice-elb"
  vpc_id      = "${aws_vpc.microservice_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Name" = "microservice-elb-public"
  }
}
