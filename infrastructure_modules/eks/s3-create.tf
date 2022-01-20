module "s3bucket" {
  count          = 1 # 1 or 0
  source         = "./S3-Source"
  s3_bucket_name = "jv-eks-irsa"
  account_id     = data.aws_caller_identity.current.account_id
  #   common_tags    = var.tags
}
