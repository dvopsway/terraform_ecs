/**
 * Launch-configuration for ECS
 */
resource "aws_launch_configuration" "ecs" {
  name                 = "${var.microservice_name}-ecs"
  image_id             = "${var.ecs_ami}"
  instance_type        = "${var.ecs_instance_type}"
  key_name             = "${var.keyname}"
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
  container_definitions = "${format(file("task-definitions/image.json"),"${var.microservice_name}","${var.imagename}")}"
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
