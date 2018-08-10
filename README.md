# Amazon AWS EKS and RDS PostgreSQL with terraform

## Initial tooling setup aws-cli, kubectl and terraform

## 1st step is to set authentication to AWS "assuming you already have AWS account and got Access Key and Security key"

```sh
aws configure
```

## 2nd step is to setup Terraform Admin account

### Create IAM terraform User

```sh
aws iam create-user --user-name terraform
```

### Add to newly created terrafom user IAM admin policy

```sh
aws iam attach-user-policy --user-name terraform --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### Create access keys for the user

```sh
aws iam create-access-key --user-name terraform
```

### Create terraform  state bucket

```sh
aws s3 mb s3://terra-state-bucket --region us-west-2
```

### Enable versioning on the bucket

```sh
aws s3api put-bucket-versioning --bucket terra-state-bucket --versioning-configuration Status=Enabled
```

## Working with terraform

## initial setup create new work space

```sh
# cd into project folder and create workspace for dev and prod
# create dev workspace
terraform workspace new dev

# list available workspace
terraform workspace list

# select dev workspace
terraform workspace select dev
```

### 1st step initiate terraform setup

```sh
# initialize and pull terraform cloud specific dependencies
terraform init
```

### Sync terraform modules

```sh
terraform get -update
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

### View creates infrastructure

```sh
terraform show && \
terraform state list && \
terraform output
```

terraform output config_map_aws_auth > ~/sources/test/config-map-aws-auth.yaml
terraform output kubeconfig > ~/sources/test/


kubectl apply -f ~/sources/test/config-map-aws-auth.yaml


