data "aws_region" "current" {}

locals {
  aws_managed_prometheus = [{
    name  = "serviceAccounts.server.name"
    value = var.service_account_amp_ingest_name
    },
    {
      name  = "serviceAccounts.server.annotations.eks\\.amazonaws\\.com/role-arn"
      value = var.amp_ingest_role_arn
    },
    {
      name  = "server.remoteWrite[0].url"
      value = "https://aps-workspaces.${data.aws_region.current.id}.amazonaws.com/workspaces/${var.amp_workspace_id}/api/v1/remote_write"
    },
    {
      name  = "server.remoteWrite[0].sigv4.region"
      value = data.aws_region.current.id
  }]

  default_set_values = [{
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
    },
    {
      name  = "kube-state-metrics.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
    {
      name  = "nodeExporter.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
    {
      name  = "pushgateway.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
    {
      name  = "alertmanager.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
    {
      name  = "server.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
  ]
  set_values = var.aws_managed_prometheus_enable == true ? concat(local.aws_managed_prometheus, local.default_set_values) : local.default_set_values

  default_prometheus_helm_app = {
    name                       = "prometheus"
    chart                      = "prometheus"
    repository                 = "https://prometheus-community.github.io/helm-charts"
    version                    = "14.4.0"
    namespace                  = "prometheus"
    timeout                    = "1200"
    create_namespace           = true
    description                = "Prometheus helm Chart deployment configuration"
    lint                       = false
    values                     = null
    wait                       = true
    wait_for_jobs              = false
    verify                     = false
    set                        = local.set_values
    set_sensitive              = null
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
  prometheus_helm_app = merge(
    local.default_prometheus_helm_app,
  var.prometheus_helm_chart)
}
