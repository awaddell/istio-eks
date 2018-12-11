Prerequisites

key pair in the target region called 'eks-worker'  (or change the template)
not doing a yum update on workers for expediency


# initialise terraform modules, backend and providers
terraform init

# run terraform plan
AWS_PROFILE=deloitte terraform plan    --var-file=../terraform.tfvars
AWS_PROFILE=deloitte terraform apply   --var-file=../terraform.tfvars
AWS_PROFILE=deloitte terraform destroy --var-file=../terraform.tfvars


AWS_PROFILE=deloitte kubectl --insecure-skip-tls-verify=true --kubeconfig kubeconfig_demo-dev-cluster cluster-info
AWS_PROFILE=deloitte kubectl --insecure-skip-tls-verify=true --kubeconfig kubeconfig_demo-dev-cluster get nodes
AWS_PROFILE=deloitte kubectl --insecure-skip-tls-verify=true --kubeconfig kubeconfig_demo-dev-cluster get pods --all-namespaces

