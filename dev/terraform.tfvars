# the aws region for the VPC and cluster
aws_region = "us-west-2"

# name to use to identify the cluster
cluster_name = "demo-dev-cluster"

# AMI ID for the eks workers (must be available in aws_region)
eks_ami_id = "ami-0f54a2f7d2e9c88b3"

# instance type for the eks workers
eks_instance_type = "t2.small"

# eks module version to download
eks_module_version = "1.8.0"

# ssh key (already uploaded to AWS) for the eks workers
eks_ssh_key = "eks-worker"

# environment (dev/prod)
environment = "dev"

# name to use to identify the VPC
vpc_name = "demo-dev-vpc"
