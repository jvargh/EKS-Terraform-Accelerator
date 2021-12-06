
locals {
  default_aws_for_fluentbit_helm_app = {
    name             = "fluent-bit"
    chart            = "fluent-bit"
    repository       = "https://fluent.github.io/helm-charts"
    version          = "0.15.15"
    namespace        = "splunk-logging"
    timeout          = "1200"
    create_namespace = true
    values = [templatefile("${path.module}/fluentbit-for-splunk-values.yaml", {
    })]
    set = [
      {
        name  = "nodeSelector.kubernetes\\.io/os"
        value = "linux"
      }
    ]
    set_sensitive              = null
    lint                       = true
    wait                       = true
    wait_for_jobs              = false
    description                = "fluentbit-for-Splunk Helm Chart deployment configuration"
    verify                     = false
    keyring                    = ""
    repository_key_file        = ""
    repository_cert_file       = ""
    repository_ca_file         = ""
    repository_username        = ""
    repository_password        = ""
    disable_webhooks           = false
    reuse_values               = false
    reset_values               = false
    force_update               = false
    recreate_pods              = false
    cleanup_on_fail            = false
    max_history                = 0
    atomic                     = false
    skip_crds                  = false
    render_subchart_notes      = true
    disable_openapi_validation = false
    dependency_update          = false
    replace                    = false
    postrender                 = ""
  }

  aws_for_fluentbit_helm_app = merge(local.default_aws_for_fluentbit_helm_app,
  var.aws_for_fluentbit_helm_chart)
}
