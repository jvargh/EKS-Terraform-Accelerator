terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.60.0"
      # version = ">= 3.66.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.5.0"
      # version = ">= 2.7.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.3.0"
      # version = ">= 2.4.1"
    }
  }
}

provider "aws" {
  region = data.aws_region.current.id
  alias  = "default"
}

terraform {
  backend "local" {
    path = "local_tf_state/terraform-main.tfstate"
  }
}


#---------------------------------------------------------------
# VPC Endpoint Gateway
#---------------------------------------------------------------
module "vpc_endpoint_gateway" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "v3.2.0"

  create = local.create_vpc_endpoints
  vpc_id = local.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = local.private_route_table_ids
      tags            = { Name = "S3-VPC-Gateway" }
    },
  }
}


module "vpc_endpoints_gateway" {
  count = local.create_vpc_endpoints == true ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "v3.2.0"

  vpc_id             = local.vpc_id
  security_group_ids = local.default_security_group_id
  subnet_ids         = local.private_subnets

  endpoints = {
    ssm = {
      service             = "ssm"
      private_dns_enabled = false
    },
    logs = {
      service             = "logs"
      private_dns_enabled = false
    },
    autoscaling = {
      service             = "autoscaling"
      private_dns_enabled = false
    },
    sts = {
      service             = "sts"
      private_dns_enabled = false
    },
    # elasticloadbalancing = {
    #   service             = "elasticloadbalancing"
    #   private_dns_enabled = true
    # },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = false
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = false
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = false
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = false
    },
    kms = {
      service             = "kms"
      private_dns_enabled = false
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = false
    },
  }
  tags = merge(local.tags, {
    Project  = "EKS"
    Endpoint = "true"
  })
}


#---------------------------------------------------------------
# Example to consume aws-eks-accelerator-for-terraform module
#---------------------------------------------------------------
module "aws-eks-accelerator-for-terraform" {
  source            = "../../infrastructure_modules/eks"
  tenant            = local.tenant
  environment       = local.environment
  zone              = local.zone
  terraform_version = local.terraform_version

  # add roles that can access EKS cluster
  map_roles = local.map_roles

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id               = local.vpc_id
  private_subnet_ids   = local.private_subnets
  pc_security_group_id = local.pc_security_group_id

  # EKS CONTROL PLANE VARIABLES
  create_eks         = local.create_eks
  kubernetes_version = local.kubernetes_version

  # EKS Managed Add-ons
  enable_eks_addon_vpc_cni            = true
  enable_eks_addon_coredns            = true
  enable_eks_addon_kube_proxy         = true
  enable_eks_addon_aws_ebs_csi_driver = true
  enable_s3_irsa                      = true

  #---------------------------------------------------------#
  # EKS WORKER NODE GROUPS
  # Define Node groups as map of maps object as shown below. Each node group creates the following
  #    1. New node group
  #    2. IAM role and policies for Node group
  #    3. Security Group for Node group (Optional)
  #    4. Launch Templates for Node group   (Optional)
  #---------------------------------------------------------#
  enable_managed_nodegroups = local.enable_managed_nodegroups
  managed_node_groups = {
    #---------------------------------------------------------#
    # ON-DEMAND Worker Group - Worker Group - 1
    #---------------------------------------------------------#
    mg_4 = {
      # 1> Node Group configuration - Part1
      node_group_name        = "managed-ondemand" # Max 40 characters for node group name
      create_launch_template = true               # false will use the default launch template
      launch_template_os     = "amazonlinux2eks"  # amazonlinux2eks or windows or bottlerocket
      public_ip              = true               # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;
      pre_userdata           = <<-EOT
            yum install -y amazon-ssm-agent
            systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent"
        EOT
      # 2> Node Group scaling configuration
      desired_size    = 1
      max_size        = 1
      min_size        = 1
      max_unavailable = 1 # or percentage = 20

      # 3> Node Group compute configuration
      ami_type       = "AL2_x86_64"  # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM
      capacity_type  = "ON_DEMAND"   # ON_DEMAND or SPOT
      instance_types = ["t3.medium"] # List of instances used only for SPOT type
      disk_size      = 50

      # 4> Node Group network configuration
      # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']      
      subnet_ids = local.private_subnets

      k8s_taints = []

      k8s_labels = {
        Environment = "preprod"
        Zone        = "dev"
        WorkerType  = "ON_DEMAND"
      }
      additional_tags = {
        ExtraTag    = "m5x-on-demand"
        Name        = "m5x-on-demand"
        subnet_type = "private"
      }

      create_worker_security_group = false
    },
  } # END OF MANAGED NODE GROUPS


  #---------------------------------------
  # METRICS SERVER HELM ADDON
  #---------------------------------------
  metrics_server_enable = false

  # # Optional Map value
  # metrics_server_helm_chart = {
  #   name       = "metrics-server"                                    # (Required) Release name.
  #   repository = "https://kubernetes-sigs.github.io/metrics-server/" # (Optional) Repository URL where to locate the requested chart.
  #   chart      = "metrics-server"                                    # (Required) Chart name to be installed.
  #   version    = "3.5.0"                                             # (Optional) Specify the exact chart version to install. If this is not specified, the latest version is installed.
  #   namespace  = "kube-system"                                       # (Optional) The namespace to install the release into. Defaults to default
  #   timeout    = "1200"                                              # (Optional)
  #   lint       = "true"                                              # (Optional)

  #   # (Optional) Example to show how to pass metrics-server-values.yaml
  #   values = [templatefile("${path.module}/k8s_addons/metrics-server-values.yaml", {
  #     operating_system = "linux"
  #   })]
  # }

  #---------------------------------------
  # CLUSTER AUTOSCALER HELM ADDON
  #---------------------------------------
  cluster_autoscaler_enable = false

  # # Optional Map value
  # cluster_autoscaler_helm_chart = {
  #   name       = "cluster-autoscaler"                      # (Required) Release name.
  #   repository = "https://kubernetes.github.io/autoscaler" # (Optional) Repository URL where to locate the requested chart.
  #   chart      = "cluster-autoscaler"                      # (Required) Chart name to be installed.
  #   version    = "9.10.7"                                  # (Optional) Specify the exact chart version to install. If this is not specified, the latest version is installed.
  #   namespace  = "kube-system"                             # (Optional) The namespace to install the release into. Defaults to default
  #   timeout    = "1200"                                    # (Optional)
  #   lint       = "true"                                    # (Optional)

  #   # (Optional) Example to show how to pass metrics-server-values.yaml
  #   values = [templatefile("${path.module}/k8s_addons/cluster-autoscaler-vaues.yaml", {
  #     operating_system = "linux"
  #   })]
  # }

  #---------------------------------------
  # ENABLE NGINX
  #---------------------------------------
  nginx_ingress_controller_enable = false
  # # Optional nginx_helm_chart
  # nginx_helm_chart = {
  #   name       = "ingress-nginx"
  #   chart      = "ingress-nginx"
  #   repository = "https://kubernetes.github.io/ingress-nginx"
  #   version    = "3.33.0"
  #   namespace  = "kube-system"
  #   values     = [templatefile("${path.module}/k8s_addons/nginx-values.yaml", {})]
  # }

  #---------------------------------------
  # AWS-FOR-FLUENTBIT HELM ADDON
  #---------------------------------------
  # aws_for_fluentbit_enable = false
  fluentbit_for_splunk_enable = true

  # aws_for_fluentbit_helm_chart = {
  #   name                                      = "aws-for-fluent-bit"
  #   chart                                     = "aws-for-fluent-bit"
  #   repository                                = "https://aws.github.io/eks-charts"
  #   version                                   = "0.1.0"
  #   namespace                                 = "logging"
  #   aws_for_fluent_bit_cw_log_group           = "/${local.cluster_name}/worker-fluentbit-logs" # Optional
  #   aws_for_fluentbit_cwlog_retention_in_days = 90
  #   create_namespace                          = true
  #   values = [templatefile("${path.module}/k8s_addons/aws-for-fluentbit-values.yaml", {
  #     region                          = data.aws_region.current.name,
  #     aws_for_fluent_bit_cw_log_group = "/${local.cluster_name}/worker-fluentbit-logs"
  #   })]
  #   set = [
  #     {
  #       name  = "nodeSelector.kubernetes\\.io/os"
  #       value = "linux"
  #     }
  #   ]
  # }
}

