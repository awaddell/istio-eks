terraform {
  required_version = ">= 0.11.8"

  backend "local" {
    path = "../terraform.tfstate"
  }
}

variable "aws_region" {}
variable "environment" {}
variable "vpc_name" {}

provider "aws" {
  region  = "${var.aws_region}"
  version = "~> 1.51"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "1.46.0"
  name            = "${var.vpc_name}"
  cidr            = "10.0.0.0/16"
  azs             = ["${data.aws_availability_zones.available.names[0]}", "${data.aws_availability_zones.available.names[1]}"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  # Single NAT Gateway 
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
