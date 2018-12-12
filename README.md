# Deploying a container application to AWS EKS

## Overview

- Kubernetes speeds deployments and provides a declarative configuration enabling a GitOps workflow.
- AWS EKS provides a managed Kubernetes cluster
- Terraform is a GitOps-friendly and well-known way to standup a VPC and EKS cluster
- Helm will assist with packaging Kubernetes deployments
- Istio will provide security within a service mesh  where we replace the 'perimeter and segments' paradigm that goes hand-in-hand with managing IP addresses and network paths, and instead, use a services paradigm where all services in the mesh verify their identify and use mutual TLS for authentication and encryption.

Finally, we will standup components representing a traditional 3-tier archetecture withing the mesh
- Db (mysql from helm)
- App (one or more simple backend apps)
- Web (a L7 tier to do simple manipulation)

And we will provide a load-balancer from Amazon as ingress for the application.


## Infrastructure Components
- Infrastructure build with Terraform
  - VPC and EKS components
  - Leverage terraform-aws modules for the heavy-lifting
  - Apply requisite IAM roles
  - Creates kubeconfig

## Kubernetes Components
- Helm for deployments
- Istio for security 


Prerequisites:

Account in us-west-2
key pair in the target region called 'eks-worker'  (or change the template)

AWS CLI
aws-iam-authenticator
```shell
go get -u -v \
github.com/kubernetes-sigs/aws-iam-authenticator/cmd/aws-iam-authenticator
```

- Terraform 0.11.10
- Kubernetes CLI (kubectl) 1.10.7
- Helm 2.12
- Istio 1.0.4

```shell
curl -L https://git.io/getLatestIstio | sh -
cd istio-1.*
```
From the Istio root dir, install the service account for Helm

```
kubectl create -f install/kubernetes/helm/helm-service-account.yaml

helm init --service-account tiller 
```

```shell
helm install \
    --wait \
    --name istio \
    --namespace istio-system \
    install/kubernetes/helm/istio

kubectl label namespace default istio-injection=enabled
```

```shell
kubectl get pods -n istio-system
NAME                                      READY     STATUS    RESTARTS   AGE
istio-citadel-cb5b884db-28kgs             1/1       Running   0          13h
istio-egressgateway-dc49b5b47-gspf4       1/1       Running   0          13h
istio-galley-5b494c7f5-zh4v5              1/1       Running   0          13h
istio-ingressgateway-64cb7d5f6d-2ll4h     1/1       Running   0          13h
istio-pilot-85747ff88-r46t5               2/2       Running   0          13h
istio-policy-858884d9c-nmv5z              2/2       Running   0          13h
istio-sidecar-injector-7f4c7db98c-dgnrc   1/1       Running   0          13h
istio-telemetry-748d58f6c5-l8b4q          2/2       Running   0          13h
prometheus-f556886b8-48nj5                1/1       Running   0          13h
```



# Initialise terraform modules, backend and providers
cd <root_of_repo>
for i in vpc eks; do terraform init dev/$i;done

# run terraform from root of repo
AWS_PROFILE=demo terraform plan    --var-file=dev/terraform.tfvars dev/vpc/
AWS_PROFILE=demo terraform apply   --var-file=dev/terraform.tfvars dev/vpc/
AWS_PROFILE=demo terraform destroy --var-file=dev/terraform.tfvars


AWS_PROFILE=demo kubectl --insecure-skip-tls-verify=true --kubeconfig kubeconfig_demo-dev-cluster cluster-info
AWS_PROFILE=demo kubectl --insecure-skip-tls-verify=true --kubeconfig kubeconfig_demo-dev-cluster get nodes
AWS_PROFILE=demo kubectl --insecure-skip-tls-verify=true --kubeconfig kubeconfig_demo-dev-cluster get pods --all-namespaces

You can verify the worker nodes are joining the cluster via: kubectl get nodes --watch 


terraform init -input=false to initialize the working directory.
terraform plan -out=tfplan -input=false to create a plan and save it to the local file tfplan.
terraform apply -input=false tfplan to apply the plan stored in the file tfplan. 


cd /
terraform init dev/vpc/ 
AWS_PROFILE=demo terraform plan   --var-file=dev/terraform.tfvars -state=dev/vpc/terraform.tfstate dev/vpc/ 
AWS_PROFILE=demo terraform apply  --var-file=dev/terraform.tfvars -state=dev/vpc/terraform.tfstate dev/vpc/   

terraform init dev/eks/ 
AWS_PROFILE=demo terraform plan   --var-file=dev/terraform.tfvars -state=dev/eks/terraform.tfstate dev/eks/    
AWS_PROFILE=demo terraform apply  --var-file=dev/terraform.tfvars -state=dev/eks/terraform.tfstate dev/eks/    


export AWS_PROFILE=demo
export KUBECONFIG=$(pwd)/kubeconfig_demo-dev-cluster

## helm

install helm locally

verify and asset tiller not installed

> helm version
Client: &version.Version{SemVer:"v2.12.0", GitCommit:"d325d2a9c179b33af1a024cdb5a4472b6288016a", GitTreeState:"clean"}
Error: could not find tiller

## Istio



## Cleanup

AWS_PROFILE=demo terraform destroy   --var-file=dev/terraform.tfvars -state=dev/eks/terraform.tfstate dev/eks/ 
