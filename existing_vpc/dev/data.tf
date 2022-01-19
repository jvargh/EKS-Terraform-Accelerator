data "aws_region" "current" {}
data "aws_caller_identity" "this" {}

locals {
  tenant      = "public01" # AWS account name or unique id for tenant
  environment = "preprod"  # Environment area eg., preprod or prod
  zone        = "dev"      # Environment with in one sub_tenant or business unit

  kubernetes_version = "1.21"
  tags               = tomap({ "created-by" = local.terraform_version })

  vpc_cidr               = "172.31.0.0/16"
  cluster_name           = join("-", [local.tenant, local.environment, local.zone, "eks"])
  aws_availability_zones = ["us-east-1a", "us-east-1b"]

  vpc_id                  = "vpc-096d1e797f3c5f224"
  private_subnets         = ["subnet-043f96dabd9d75e29", "subnet-045b2813236f023b3"]
  private_route_table_ids = ["rtb-042377d27c0071a0a"]

  # Bastion host or Cloud9 security group to get access to EKS Private API endpoint. Add this to EKS Cluster SG
  default_security_group_id = ["sg-0748b468cf8a7f600"]
  pc_security_group_id      = ["sg-0f625e6d0296c7db3"]

  terraform_version = "Terraform v0.14.11"

  map_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/eks-admin" # create IAM role in Console
      username = "eks_admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/eks-developer" # create IAM role in Console
      username = "eks-developer"
      groups   = ["eks-developer"]
    },
  ]

  # Enable=true Disable=false: this creates/destroys EKS, VPC-E, EKS Managed Node Group as needed
  # Setting create_eks=true creates new VPC. No VPC peering needed as all in same VPC. pc_sec_grpid will be added to cluster_sec_grp
  # Setting all to false should remove but if issue with auth remval, run below to remove this module and t apply again 
  #     t state rm module.aws-eks-accelerator-for-terraform.kubernetes_config_map.aws_auth[0]
  create_eks                = true
  create_vpc_endpoints      = false
  enable_managed_nodegroups = true
}
