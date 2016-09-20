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

variable "nat_ami" {
  default = "ami-311a1a5b"
}

variable "ecs_ami" {
  default = "ami-3d55272a"
}

variable "ecs_instance_type" {
  default = "t2.medium"
}

variable "keyname" {
  default = ""
}

variable "vpc_cidr" {
  default = "10.202.0.0/23"
}
