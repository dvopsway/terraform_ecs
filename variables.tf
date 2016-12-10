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

variable "keyname" {
  default = ""
}

variable "vpc_cidr" {
  default = "10.0.0.0/23"
}
