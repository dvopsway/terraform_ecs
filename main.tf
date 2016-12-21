/**
 * Run a fully managed ecs cluster:
 * 
 * Components Launched
 *  - HA VPC with public , private subnets, SG, NACL and NAT
 *  - Autoscaling Group
 *  - ECS cluster
 *  - ELB endpoints 
 *  
 * Usage:
 *
 *      module "magnify" {
 *		  access_key           = "xxxxxxxxxxxxxxxxxxxxxxxx"
 *		  secret_key           = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
 *        source               = "github.com/dvopsway/terraform_ecs"
 *        microservice_name    = "magnify"
 *        imagename            = "padmakarojha/magnify"
 *        region               = "us-east-1"
 *        az                   = {
 *         	zone1 = "us-east-1b"
 *          zone2 = "us-east-1c" 
 *        }
 *        vpc_cidr             = "10.200.50.0/23"
 *        key_name             = "ecs-test"
 *      }
 *
 */

variable "access_key" {}

variable "secret_key" {}

variable "microservice_name" {
  default = "testing"
}

variable "imagename" {
  default = "padmakarojha/magnify"
}

variable "region" {
  default = "us-east-1"
}

variable "az" {
  default = {
    "zone1" = "us-east-1b"
    "zone2" = "us-east-1c"
  }
}

/**
 * HVM NAT AMI for US-EAST-1
 * Created: October 29, 2016 at 6:26:48 AM UTC+5:30
 */
variable "nat_ami" {
  default = "ami-863b6391"
}

/**
 * ECS Optimized AMI for US-EAST-1
 * Version: 2016.09.c
 */
variable "ecs_ami" {
  default = "ami-6df8fe7a"
}

variable "ecs_instance_type" {
  default = "t2.medium"
}

variable "key_name" {
  default = ""
}

variable "vpc_cidr" {
  default = "10.0.0.0/23"
}

provider "aws" {
  region     = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

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

/**
 * The NAT instance for microservices
 */
resource "aws_instance" "microservice_nat" {
  ami                    = "${var.nat_ami}"
  ebs_optimized          = false
  instance_type          = "t2.micro"
  monitoring             = true
  key_name               = "${var.key_name}"
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

resource "aws_eip" "nat1_ip" {
  instance   = "${aws_instance.microservice_nat.id}"
  vpc        = true
  depends_on = ["aws_instance.microservice_nat"]
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

resource "aws_iam_role" "ecs_instance" {
  name = "ecs_instance"
  path = "/"

  assume_role_policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "ecs_instance_policy" {
  name = "test_policy"
  role = "${aws_iam_role.ecs_instance.id}"

  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "ecs:CreateCluster",
       "ecs:DeregisterContainerInstance",
       "ecs:DiscoverPollEndpoint",
       "ecs:Poll",
       "ecs:RegisterContainerInstance",
       "ecs:StartTelemetrySession",
       "ecs:Submit*",
       "ecr:GetAuthorizationToken",
       "ecr:BatchCheckLayerAvailability",
       "ecr:GetDownloadUrlForLayer",
       "ecr:BatchGetImage",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "*"
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_service" {
  name = "ecs_service"
  path = "/"

  assume_role_policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "ecs_service_policy" {
  name = "test_policy"
  role = "${aws_iam_role.ecs_service.id}"

  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "ec2:AuthorizeSecurityGroupIngress",
       "ec2:Describe*",
       "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
       "elasticloadbalancing:DeregisterTargets",
       "elasticloadbalancing:Describe*",
       "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
       "elasticloadbalancing:RegisterTargets"
     ],
     "Resource": "*"
   }
 ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name  = "ecs_instance"
  path  = "/"
  roles = ["${aws_iam_role.ecs_instance.name}"]
}

/**
 * Launch-configuration for ECS
 */
resource "aws_launch_configuration" "ecs" {
  name                 = "${var.microservice_name}-ecs"
  image_id             = "${var.ecs_ami}"
  instance_type        = "${var.ecs_instance_type}"
  key_name             = "${var.key_name}"
  security_groups      = ["${aws_security_group.microservice_ecs.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs_instance.name}"
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.microservice.name} > /etc/ecs/ecs.config"
}

/**
 * Autoscale group for ECS
 */
resource "aws_autoscaling_group" "ecs" {
  name                 = "${var.microservice_name}-microservice"
  vpc_zone_identifier  = ["${aws_subnet.microservice_privatesubnet.0.id}", "${aws_subnet.microservice_privatesubnet.1.id}"]
  launch_configuration = "${aws_launch_configuration.ecs.name}"
  load_balancers       = ["${aws_elb.microservice_public.name}"]
  min_size             = 2
  max_size             = 3
  desired_capacity     = 2

  tag {
    key                 = "Name"
    value               = "${var.microservice_name}"
    propagate_at_launch = true
  }
}

/**
 * ECS Cluster
 */
resource "aws_ecs_cluster" "microservice" {
  name = "${var.microservice_name}"
}

/**
 * ECS Task definitions
 */
resource "aws_ecs_task_definition" "task" {
  family                = "${var.microservice_name}"
  container_definitions = "${format(file("${path.module}/files/task-definition.json"),"${var.microservice_name}","${var.imagename}")}"
}

/**
 * ECS service creation
 */
resource "aws_ecs_service" "service" {
  name            = "${var.microservice_name}"
  task_definition = "${aws_ecs_task_definition.task.arn}"
  cluster         = "${aws_ecs_cluster.microservice.name}"
  desired_count   = 2
  iam_role        = "${aws_iam_role.ecs_service.arn}"

  load_balancer {
    elb_name       = "${aws_elb.microservice_public.name}"
    container_name = "${var.microservice_name}"
    container_port = 80
  }
}

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

output "microservice_cidr" {
  value = "${var.vpc_cidr}"
}
