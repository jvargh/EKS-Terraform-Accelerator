
locals {
  default_add_on_config = {
    addon_name               = "s3"
    service_account          = "s3-irsa-sa"
    secret_name              = "vvp-secret"
    namespace                = "kube-system"
    additional_iam_policies  = []
    service_account_role_arn = ""
    tags                     = {}
  }
  add_on_config = merge(
    local.default_add_on_config,
    var.add_on_config
  )
}
