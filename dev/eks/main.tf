terraform {
  required_version = ">= 0.11.8"
}

data "terraform_remote_state" "vpc" {
  backend = "local"
  config{
    path = "../terraform.tfstate"
  }
}
variable "cluster_name" {}
variable "environment" {}
variable "aws_region" {}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "1.8.0"
  cluster_name = "${var.cluster_name}"
  subnets = ["${data.terraform_remote_state.vpc.private_subnets}"]

  workers_group_defaults = {
    ami_id               = "ami-0f54a2f7d2e9c88b3" # AMI ID for the eks workers. If none is provided, Terraform will search for the latest version of their EKS optimized worker AMI.
    asg_desired_capacity = "2"                     # Desired worker capacity in the autoscaling group.
    asg_max_size         = "3"                     # Maximum worker capacity in the autoscaling group.
    asg_min_size         = "1"                     # Minimum worker capacity in the autoscaling group.
    instance_type        = "t2.small"              # Size of the workers instances.
    key_name             = "eks-worker"            # The key name that should be used for the instances in the autoscaling group
    additional_userdata  = ""                      # userdata to append to the default userdata.
    ebs_optimized        = true                    # sets whether to use ebs optimization on supported types.
    public_ip            = false                   # Associate a public ip address with a worker
  }

  tags = "${
    map(
     "Name", "terraform-eks-demo-node",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
    )
  }"

  vpc_id          = "${data.terraform_remote_state.vpc.vpc_id}"
  manage_aws_auth = true
}
