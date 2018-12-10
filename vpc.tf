terraform {
  required_version = ">= 0.11.8"
}

variable "cluster_name" {}
variable "aws_region" {}

provider "aws" {
  region  = "${var.aws_region}"
  version = "~> 1.51"
}

data "aws_availability_zones" "available" {}

# provider.local: version = "~> 1.1"
# provider.null: version = "~> 1.0"
# provider.template: version = "~> 1.0"

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "1.46.0"
  name            = "my-vpc"
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

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "1.8.0"
  cluster_name = "${var.cluster_name}"
  subnets      = ["${module.vpc.private_subnets}"]

  tags = "${
    map(
     "Name", "terraform-eks-demo-node",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
    )
  }"

  vpc_id          = "${module.vpc.vpc_id}"
  manage_aws_auth = true
}
