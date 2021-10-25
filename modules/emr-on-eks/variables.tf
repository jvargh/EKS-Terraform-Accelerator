variable "emr_on_eks_username" {
  type    = string
  default = "emr-containers"
}

variable "emr_on_eks_namespace" {
  type    = string
  default = "spark"
}

variable "emr_on_eks_iam_role_name" {
  type    = string
  default = "emr_on_eks"
}

variable "environment" {
  type = string
}

variable "tenant" {
  type = string
}

variable "zone" {
  type = string
}

variable "eks_cluster_id" {
  type = string
}
