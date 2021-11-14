# Existing VPC EKS Cluster Deployment in a Private EKS network

The following steps walks you through the deployment of this example

This example deploys a Basic EKS Cluster with Managed Node group with the following pre-requisites

- Existing VPC CIDR and VPC ID
- AWS Availability Zones
- Existing Private Subnet IDs from the above AZs
- Private Route Table
- Security Group ID of the Bastion or Cloud9 host

# How to Deploy

## Prerequisites:

Ensure that you have installed the following tools in your Mac or Windows Laptop before start working with this module and run Terraform Plan and Apply

1. [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. [aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
3. [kubectl](https://Kubernetes.io/docs/tasks/tools/)
4. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Deployment Steps

#### Step1: Clone the repo using the command below

```shell
git clone https://github.com/jvargh/eks-tf-accelerator-3.0.git
```

#### Step2: Run Terraform INIT

to initialize a working directory with configuration files

```shell
cd deploy/existing_vpc/
terraform init
```

#### Step3: Run Terraform PLAN

to verify the resources created by this execution

```shell
export AWS_REGION="us-east-1"   # Select your own region
terraform plan
```

#### Step4: Enable eks

to create resources. Ensure adding Bastion or Cloud9 Security Group to EKS Cluster Security Group at this point

```shell
create_eks = true
```

#### Step5: Terraform APPLY

to create resources

```shell
terraform apply
```

Enter `yes` to apply

#### Step6: Enable vpc_endpoints, managed_node-groups

to create resources

```shell
create_vpc_endpoints=true (with terraform apply), following which enable_managed_nodegroups=true (with terraform apply)
```


### Configure kubectl and test cluster

EKS Cluster details can be extracted from terraform output or from AWS Console to get the name of cluster. This following command used to update the `kubeconfig` in your local machine where you run kubectl commands to interact with your EKS Cluster.

#### Step5: Run update-kubeconfig command.
`~/.kube/config` file gets updated with cluster details and certificate from the below command

$ aws eks --region us-east-1 update-kubeconfig --name `<cluster-name>`

#### Step6: List all the worker nodes by running the command below
$ kubectl get nodes

#### Step7: List all the pods running in kube-system namespace
$ kubectl get pods -n kube-system

# How to Destroy
```shell
cd deploy/existing_vpc/
terraform destroy
```

## Authentication and Authorization 
#### Step 1a: Verify IAM roles specified in map_roles local var are added to aws-auth configmap
> kubectl describe cm aws-auth -n kube-system
mapRoles:
----
- "groups":
  - "system:masters"
  "rolearn": "arn:aws:iam::<account_id>:role/eks-admin"
  "username": "eks_admin"
- "groups":
  - "eks-developer"
  "rolearn": "arn:aws:iam::<account_id>:role/eks-developer"
  "username": "eks-developer"

#### Step 1b: Verify ClusterRoleBinding creates Group=eks-developer
Run clusterrolebinding_eks_developer.yml to associate ClusterRole=view with newly created Group
> kubectl describe clusterrolebinding -name eks-developer
Role:
  Kind:  ClusterRole
  Name:  view
Subjects:
  Kind   Name           Namespace
  ----   ----           ---------
  Group  eks-developer  

#### Step 2: Create EKSDeveloperRoleAssumeRolePolicy so IAM users can assume Developer role
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::xxx:role/eks-developer"
        }
    ]
}

#### Step 3: Create IAM Role eks-developer which contains permissions (S3 Read access)
From IAM create role 'eks-developer' that matches aws-auth. Assign policies that provide AWS permissions as e.g. AmazonS3ReadOnlyAccess

#### Step 4: Create IAM user eks-developer1 and attach EKSDeveloperRoleAssumeRolePolicy IAM policy 
From IAM create user 'eks-developer1'. Attach IAM policy EKSDeveloperRoleAssumeRolePolicy.
Due to policy, user should be able to assume role 'eks-developer'

#### Step 5: Add IAM user eks-developer1 details to .aws/config and .aws/credentials
Add below to config
[eks-admin]
region = us-east-1
[profile eks-developer]

Add below to credentials
[eks-developer1]
aws_access_key_id=<access_key_from_console>
aws_secret_access_key=<secret_key_from_console>

#### Step 6: Test permission for eks-developer1
Run below. First activate user profile through export. Viewing cmds should work but not admin cmds
> export AWS_PROFILE=eks-developer
> kubectl get all  
<works with expected output>
> kubectl describe clusterrolebinding -name eks-developer
Error from server (Forbidden): clusterrolebindings.rbac.authorization.k8s.io "eks-developer" is forbidden: User "eks-developer" cannot get resource "clusterrolebindings" in API group "rbac.authorization.k8s.io" at the cluster scope

