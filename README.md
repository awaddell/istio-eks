# Deploying a container application to AWS EKS

## Overview

- Kubernetes speeds deployments and provides a declarative configuration enabling a GitOps workflow.
- AWS EKS provides a managed Kubernetes cluster
- Terraform is a GitOps-friendly and well-known way to standup a VPC and EKS cluster
- Helm packages and deploys Kubernetes deployments
- Istio will provide security within a service mesh  where we replace the 'perimeter and segments' paradigm that goes hand-in-hand with managing IP addresses and network paths, and instead, use a services paradigm where all services in the mesh verify their identify and use mutual TLS for authentication and encryption.

Finally, we will standup components representing a traditional 3-tier archetecture withing the mesh
- Db (mysql from Helm)
- App (one or more simple microservices)
- Web (L7 manipulation with Istio)

## Components

- Terraform 0.11.10
- Kubernetes CLI (kubectl) 1.10.7
  - aws-iam-authenticator for RBAC
- Helm 2.12
- Istio 1.0.4

## Infrastructure Components
- Infrastructure build with Terraform
  - VPC and EKS components
    - Leverage terraform-aws modules for the heavy-lifting
    - Apply IAM roles
    - Creates NAT GW
    - Creates kubeconfig

NB Not providing a bastion for access as 
- we don't neeed SSH access to nodes
- a bastion can be stood up and torn down on-demand as a separate exercise

## Kubernetes Components
- Helm for deployments
- Istio for security 

Prerequisites:

- Account in us-west-2 (corresponding with the AMI used)
- key pair in the target region called 'eks-worker'  (or change the template)
- AWS CLI profile configured for above account

### Install the aws-iam-authenticator
```shell
go get -u -v \
github.com/kubernetes-sigs/aws-iam-authenticator/cmd/aws-iam-authenticator
```

export the AWS profile to the environment

    export AWS_PROFILE=demo

### Initialise terraform modules, backend and providers for the vpc module

```shell
cd <root_of_repo>
terraform init dev/vpc/
```

### Install the VPC component

```shell
terraform plan \
--var-file=dev/terraform.tfvars \
-state=dev/vpc/terraform.tfstate \
dev/vpc/ 

terraform apply \
--var-file=dev/terraform.tfvars \
-state=dev/vpc/terraform.tfstate \
dev/vpc/
```

### Initialise terraform modules, backend and providers for the eks module

```shell
cd <root_of_repo>
terraform init dev/eks/
```

### Install the EKS component

```shell
terraform plan \
--var-file=dev/terraform.tfvars \
-state=dev/eks/terraform.tfstate \
dev/eks/    

terraform apply \
--var-file=dev/terraform.tfvars \
-state=dev/eks/terraform.tfstate \
dev/eks/  
```

*I deployed the above successfully four times and then, on the fifth deployment got a 400 error from the AWS API which was resolved by running the plan and apply again (for eks)*

After successful deployment of EKS, configure the KUBECONTEXT

(Still from the root of the repo)

```shell
export KUBECONFIG=$(pwd)/kubeconfig_demo-dev-cluster
```

Verify API access to the cluster:

```
kubectl cluster-info

kubectl get nodes

kubectl get pods --all-namespaces
```

Note that kubectl still relies on the exported AWS_PROFILE (for the aws-iam-authenticator to fetch RBAC permissions)

Without it, you'll get an error like

*could not get token: NoCredentialProviders: no valid providers in chain. Deprecated.
        For verbose messaging see aws.Config.CredentialsChainVerboseErrors
Unable to connect to the server: getting token: exec: exit status 1*

## Helm

Install helm locally per https://docs.helm.sh/using_helm/#installing-helm

Do not install Tiller at this point.

## Istio

Fetch the latest Istio release

```shell
curl -L https://git.io/getLatestIstio | sh -
cd istio-1.*
```
**From the Istio root dir**, install the service account for Helm and initialise Helm

```
kubectl create -f install/kubernetes/helm/helm-service-account.yaml

helm init --service-account tiller 
```

Verify that Tiller pod and service is running 

```shell
kubectl get pod --namespace kube-system
kubectl get pod, svc --namespace kube-system
```

Install Istio to the cluster

NB I had an issue that heml complains crd already exists.
At this stage, I am trying to work around it with 


### Default: does not currently work for me
```shell
helm install \
    --wait \
    --name istio \
    --namespace istio-system \
    install/kubernetes/helm/istio
```

### Workaround: 

#### Install the CRDs first

    kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml 

#### Install Istio using '--no-crd-hook'

```shell
helm install \
--no-crd-hook \
--wait \
--name istio \
--namespace istio-system \
install/kubernetes/helm/istio
```
    kubectl label namespace default istio-injection=enabled


If you still get 

```
Error: release istio failed: customresourcedefinitions.apiextensions.k8s.io "bypasses.config.istio.io" already exists
```

then you've hit the same issue

cleanup the deployment

```shell
helm ls --all
helm delete --purge istio
```

This should delete all the crds but, for good measure, 

    kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system

#### A Successful Istio installation

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

## Cleanup

```shell
cd <root of repo>

terraform destroy \
--var-file=dev/terraform.tfvars \
-state=dev/eks/terraform.tfstate \
dev/eks/ 

terraform destroy \
--var-file=dev/terraform.tfvars \
-state=dev/vpc/terraform.tfstate \
dev/vpc/
```