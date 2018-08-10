# Amazon AWS EKS and RDS PostgreSQL with terraform

This is the second part of the 3 part  series article on how to use terraform to deploy on Cloud providers Kubernetes offerings. In previous [Article](https://medium.com/@mudrii/google-gke-and-sql-with-terraform-294fb840619d) I showed how you can deploy complete kubernetes setup on [Google Cloud GKE](https://cloud.google.com/kubernetes-engine/) and [PostgreSQL](https://www.postgresql.org/) google sql offering.
In this Article I will show how can you deploy [Amazon AWS EKS](https://aws.amazon.com/eks/) and RDS with terraform.
As AWS EKS is most recent service Amazon AWS cloud provider that adopted GKE Managed Kubernetes, be aware about the additional cost of  $0.20 per hour for the EKS Control Plane "Kubernetes Master", and usual EC2, EBS,etc prices for resources that run in your account.
As comparing EKS with GKE is not so strait forward to deploy and configure requires more moving pieces like setting up AWS launch configuration and AWS autoscaling group and in addition IAM roles and policy to allow AWS to manage EKS.

```text
NOTE: This tutorial is not secured and is not production ready
```

**Article is structured in 5 parts**

* Initial tooling setup aws cli , kubectl and terraform
* Creating terraform IAM account with access keys and access policy
* Creating back-end storage for tfstate file in AWS S3 
* Creating Kubernetes cluster on AWS EKS and RDS on PostgreSQL
* Working with kubernetes "kubectl" in EKS

## Initial tooling setup aws-cli, kubectl, terraform and aws-iam-authenticator

Assuming you already have AWS account and [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html) and [AWS CLI configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) for your user account we will need additional binaries for, terraform and kubectl.

### Deploying terraform

#### terraform for OS X

```sh
curl -o terraform_0.11.7_darwin_amd64.zip https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_darwin_amd64.zip

unzip terraform_0.11.7_linux_amd64.zip -d /usr/local/bin/
```

#### terraform for Linux

```sh
curl https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip > terraform_0.11.7_linux_amd64.zip

unzip terraform_0.11.7_linux_amd64.zip -d /usr/local/bin/
```

#### terraform installation verification

Verify terraform version 0.11.7 or higher is installed:

```sh
terraform version
```

### Deploying kubectl

#### kubectl for OS X

```sh
curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/darwin/amd64/kubectl

chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

#### kubectl for Linux

```sh
wget https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64/kubectl

chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

#### kubectl installation verification

```sh
kubectl version --client
```

### Deploying aws-iam-authenticator

[aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator) is a tool developed by [Heptio](https://heptio.com/) Team and this tool will allow us to manage eks by using kubectl

#### aws-iam-authenticator for OS X

```sh
curl -o aws-iam-authenticator \
https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/darwin/amd64/aws-iam-authenticator

chmod +x ./aws-iam-authenticator

cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
```

#### aws-iam-authenticator for Linux

```sh
curl -o aws-iam-authenticator \
https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator

chmod +x ./aws-iam-authenticator

cp ./aws-iam-authenticator $HOME/.local/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
```

#### aws-iam-authenticator installation verification

```sh
aws-iam-authenticator help
```

### Authenticate to AWS

Before configuring AWS CLI as GKE at this time is only available in US East (N. Virginia) and US West (Oregon)
In below example we will be using US West (Oregon) "us-west-2"

```sh
aws configure
```

## Creating terraform IAM account with access keys and access policy

### 1nd step is to setup Terraform Admin account in AWS IAM

### Create IAM terraform User

```sh
aws iam create-user --user-name terraform
```

### Add to newly created terraform user IAM admin policy

```text
NOTE: For production or event proper testing account you may need tighten up and restrict acces for terraform IAM user
```

```sh
aws iam attach-user-policy --user-name terraform --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### Create access keys for the user

```text
NOTE: This Access Key and Secret Access Key will be used by terraform to manage infrastructure creation
```

```sh
aws iam create-access-key --user-name terraform
```

### update terraform.tfvars file with access and security keys for newly created terraform IAM account

[![asciicast](https://asciinema.org/a/195785.png)](https://asciinema.org/a/195785)

## Creating back-end storage for tfstate file in AWS S3

Once we have terraform IAM account created we can proceed to next step creating dedicated bucket to keep terraform state files

### Create terraform state bucket

```text
NOTE: Change name of the bucker, name should be unique across all AWS S3 buckets
```

```sh
aws s3 mb s3://terra-state-bucket --region us-west-2
```

### Enable versioning on the newly created bucket

```sh
aws s3api put-bucket-versioning --bucket terra-state-bucket --versioning-configuration Status=Enabled
```

[![asciicast](https://asciinema.org/a/195792.png)](https://asciinema.org/a/195792)

## Creating Kubernetes cluster on AWS EKS and RDS on PostgreSQL

Now we can move into creating new infrastructure, eks and rds with terraform

```sh
.
├── backend.tf
├── eks
│   ├── eks_cluster
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── eks_iam_roles
│   │   ├── main.tf
│   │   └── outputs.tf
│   ├── eks_node
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── userdata.tpl
│   │   └── variables.tf
│   └── eks_sec_group
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── main.tf
├── network
│   ├── route
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── sec_group
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── subnets
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
├── rds
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── README.md
├── terraform.tfvars
├── variables.tf
└── yaml
    ├── eks-admin-cluster-role-binding.yaml
    └── eks-admin-service-account.yaml
```

We will use terraform modules to keep our code clean and organized
Terraform will run 2 separate environment dev and prod using same sources only difference in this case is number of worker nodes for kubernetes.

```go
# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}

## Network
# Create VPC
module "vpc" {
  source           = "./network/vpc"
  eks_cluster_name = "${var.eks_cluster_name}"
  cidr_block       = "${var.cidr_block}"
}

# Create Subnets
module "subnets" {
  source           = "./network/subnets"
  eks_cluster_name = "${var.eks_cluster_name}"
  vpc_id           = "${module.vpc.vpc_id}"
  vpc_cidr_block   = "${module.vpc.vpc_cidr_block}"
}

# Configure Routes
module "route" {
  source              = "./network/route"
  main_route_table_id = "${module.vpc.main_route_table_id}"
  gw_id               = "${module.vpc.gw_id}"

  subnets = [
    "${module.subnets.subnets}",
  ]
}

module "eks_iam_roles" {
  source = "./eks/eks_iam_roles"
}

module "eks_sec_group" {
  source           = "./eks/eks_sec_group"
  eks_cluster_name = "${var.eks_cluster_name}"
  vpc_id           = "${module.vpc.vpc_id}"
}

module "eks_cluster" {
  source           = "./eks/eks_cluster"
  eks_cluster_name = "${var.eks_cluster_name}"
  iam_cluster_arn  = "${module.eks_iam_roles.iam_cluster_arn}"
  iam_node_arn     = "${module.eks_iam_roles.iam_node_arn}"

  subnets = [
    "${module.subnets.subnets}",
  ]

  security_group_cluster = "${module.eks_sec_group.security_group_cluster}"
}

module "eks_node" {
  source                    = "./eks/eks_node"
  eks_cluster_name          = "${var.eks_cluster_name}"
  eks_certificate_authority = "${module.eks_cluster.eks_certificate_authority}"
  eks_endpoint              = "${module.eks_cluster.eks_endpoint}"
  iam_instance_profile      = "${module.eks_iam_roles.iam_instance_profile}"
  security_group_node       = "${module.eks_sec_group.security_group_node}"

  subnets = [
    "${module.subnets.subnets}",
  ]
}

module "sec_group_rds" {
  source         = "./network/sec_group"
  vpc_id         = "${module.vpc.vpc_id}"
  vpc_cidr_block = "${module.vpc.vpc_cidr_block}"
} 


module "rds" {
  source = "./rds"

  subnets = [
    "${module.subnets.subnets}",
  ]

  sec_grp_rds       = "${module.sec_group_rds.sec_grp_rds}"
  identifier        = "${var.identifier}"
  storage_type      = "${var.storage_type}"
  allocated_storage = "${var.allocated_storage}"
  db_engine         = "${var.db_engine}"
  engine_version    = "${var.engine_version}"
  instance_class    = "${var.instance_class}"
  db_username       = "${var.db_username}"
  db_password       = "${var.db_password}"
  sec_grp_rds       = "${module.sec_group_rds.sec_grp_rds}"
}
```

Terraform modules will create

* VPC
* Subnets
* Routes
* IAM Roles for master and nodes
* Security Groups "Firewall" to allow master and nodes to communicate
* EKS cluster
* Autoscaling Group will create nodes to be added to the cluster
* Security group for RDS
* RDS with PostgreSQL

```text
NOTE: very important to keep tags as if tags is not specify nodes will not be able to join cluster
```

### Initial setup create and create new workspace for terraform

cd into project folder and create workspace for dev and prod

#### Initialize and pull terraform cloud specific dependencies

```sh
terraform init
```

#### Create dev workspace

```sh
terraform workspace new dev
```

#### List available workspace

```sh
terraform workspace list
```

#### Select dev workspace

```sh
terraform workspace select dev
```

Before we can start will need to update variables and add db password to terraform.tfvars

```sh
echo 'db_password = "Your_DB_Passwd."' >> terraform.tfvars
```

#### It's a good idea to sync terraform modules

```sh
terraform get -update
```

[![asciicast](https://asciinema.org/a/195796.png)](https://asciinema.org/a/195796)

### View terraform plan

```sh
terraform plan
```

### Apply terraform plan

```text
NOTE: building complete infrastructure may take more than 10 minutes.
```

```sh
terraform apply
```


### Apply terraform only for VPC and Subnet creation

```sh
terraform plan -target=module.vpc -target=module.subnets
terraform apply -target=module.vpc -target=module.subnets -auto-approve
```

### Export 2nd plan that will include routes rds security groups and eks

```sh
terraform plan
```

### Apply terraform for remaining routes, db eks etc.

```sh
terraform apply -auto-approve
```
[![asciicast](https://asciinema.org/a/195802.png)](https://asciinema.org/a/195802)

### Verify instance creation

```sh
aws ec2 describe-instances --output table
```

### We are not done yet

#### Create new AWS CLI profile

In order to use kubectl with EKS we need to set new AWS CLI profile

```text
NOTE: will need to use secret and access keys from terrafom.tfvrs
```

```sh
cat terraform.tfvars

aws configure --profile terraform

export AWS_PROFILE=terraform
```

#### Configure kubectl to allow us to connect to EKS cluster

In terraform configuration we output configuration file for kubectl

```sh
terraform output kubeconfig
```

#### Add output of "terraform output kubeconfig" to ~/.kube/config-devel

```sh
terraform output kubeconfig > ~/.kube/config-devel

export KUBECONFIG=$KUBECONFIG:~/.kube/config-devel
```

#### Verify kubectl connectivity

```sh
kubectl get namespaces

kubectl get services
```

#### Second part we need to allow EKS to add nodes by running configmap

```sh
terraform output config_map_aws_auth > yaml/config_map_aws_auth.yaml

kubectl apply -f yaml/config_map_aws_auth.yaml
```

#### Now you should be able to see nodes

```sh
kubectl get nodes
```

[![asciicast](https://asciinema.org/a/195818.png)](https://asciinema.org/a/195818)

## Working with terraform on EKS

### Deploy the [Kubernetes Dashboard](https://github.com/kubernetes/dashboard)

#### Deploy the Kubernetes dashboard

```sh
kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

#### Deploy heapster to enable container cluster monitoring and performance analysis on your cluster

```sh
kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml
```

#### Deploy the influxdb backend for heapster to your cluster

```sh
kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml
```

#### Create the heapster cluster role binding for the dashboard

```sh
kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml
```

### Create an eks-admin Service Account and Cluster Role Binding

#### Apply the service account to your cluster

```sh
kubectl apply -f yaml/eks-admin-service-account.yaml
```

#### Apply the cluster role binding to your cluster

```sh
kubectl apply -f yaml/eks-admin-cluster-role-binding.yaml
```

### Connect to the Dashboard

```sh
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')

kubectl proxy
```

```text
NOTE: Open the link with a web browser to access the dashboard endpoint: http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
```

```text
NOTE: Choose Token and paste output from the previous command into the Token field
```

[![asciicast](https://asciinema.org/a/195823.png)](https://asciinema.org/a/195823)

## Rolling back all changes

### Destroy all terraform created infrastructure

```sh
terraform destroy -auto-approve
```

[![asciicast](https://asciinema.org/a/195827.png)](https://asciinema.org/a/195827)

### Removing S3 bucket, IAM roles and terraform account

```sh
export AWS_PROFILE=default

aws s3 rm s3://terra-state-bucket --recursive

aws s3api put-bucket-versioning --bucket terra-state-bucket --versioning-configuration Status=Suspended

aws s3api delete-objects --bucket terra-state-bucket --delete \
"$(aws s3api list-object-versions --bucket terra-state-bucket | \
jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"

aws s3 rb s3://terra-state-bucket --force

aws iam detach-user-policy --user-name terraform --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam list-access-keys --user-name terraform  --query 'AccessKeyMetadata[*].{ID:AccessKeyId}' --output text

aws iam delete-access-key --user-name terraform --access-key-id OUT_KEY

aws iam delete-user --user-name terraform
```

Terraform and kubernetes sources can be found in [GitHub](https://github.com/mudrii/eks_rds_terraform)
