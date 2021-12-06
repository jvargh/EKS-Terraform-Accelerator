# /*
#  * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#  * SPDX-License-Identifier: MIT-0
#  *
#  * Permission is hereby granted, free of charge, to any person obtaining a copy of this
#  * software and associated documentation files (the "Software"), to deal in the Software
#  * without restriction, including without limitation the rights to use, copy, modify,
#  * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
#  * permit persons to whom the Software is furnished to do so.
#  *
#  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
#  * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
#  * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#  * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#  * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#  * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  */

module "fluent-bit-for-splunk" {
  count                        = var.create_eks && var.fluentbit_for_splunk_enable ? 1 : 0
  source                       = "./kubernetes-addons/fluentbit-for-splunk"
  # aws_for_fluentbit_helm_chart = var.aws_for_fluentbit_helm_chart
  eks_cluster_id               = module.aws_eks.cluster_id

  depends_on = [module.aws_eks]
}

# module "aws-for-fluent-bit" {
#   count                        = var.create_eks && var.aws_for_fluentbit_enable ? 1 : 0
#   source                       = "./kubernetes-addons/aws-for-fluentbit"
#   aws_for_fluentbit_helm_chart = var.aws_for_fluentbit_helm_chart
#   eks_cluster_id               = module.aws_eks.cluster_id

#   depends_on = [module.aws_eks]
# }

# module "aws_opentelemetry_collector" {
#   count  = var.create_eks && var.aws_open_telemetry_enable ? 1 : 0
#   source = "./kubernetes-addons/aws-opentelemetry-eks"

#   aws_open_telemetry_addon                 = var.aws_open_telemetry_addon
#   aws_open_telemetry_mg_node_iam_role_arns = var.create_eks && var.enable_managed_nodegroups ? values({ for nodes in sort(keys(var.managed_node_groups)) : nodes => join(",", module.aws_eks_managed_node_groups[nodes].managed_nodegroup_iam_role_name) }) : []

#   depends_on = [module.aws_eks]
# }

# module "cert_manager" {
#   # count  = var.create_eks && (var.cert_manager_enable || var.enable_windows_support) ? 1 : 0
#   count  = var.create_eks && var.cert_manager_enable ? 1 : 0
#   source = "./kubernetes-addons/cert-manager"

#   cert_manager_helm_chart = var.cert_manager_helm_chart

#   depends_on = [module.aws_eks]
# }

# module "cluster_autoscaler" {
#   count                         = var.create_eks && var.cluster_autoscaler_enable ? 1 : 0
#   source                        = "./kubernetes-addons/cluster-autoscaler"
#   eks_cluster_id                = module.aws_eks.cluster_id
#   cluster_autoscaler_helm_chart = var.cluster_autoscaler_helm_chart

#   depends_on = [module.aws_eks]
# }

# module "lb_ingress_controller" {
#   count                          = var.create_eks && var.aws_lb_ingress_controller_enable ? 1 : 0
#   source                         = "./kubernetes-addons/lb-ingress-controller"
#   eks_cluster_id                 = module.aws_eks.cluster_id
#   lb_ingress_controller_helm_app = var.aws_lb_ingress_controller_helm_app
#   eks_oidc_issuer_url            = module.aws_eks.cluster_oidc_issuer_url
#   eks_oidc_provider_arn          = module.aws_eks.oidc_provider_arn

#   depends_on = [module.aws_eks]
# }

# module "metrics_server" {
#   count                     = var.create_eks && var.metrics_server_enable ? 1 : 0
#   source                    = "./kubernetes-addons/metrics-server"
#   metrics_server_helm_chart = var.metrics_server_helm_chart

#   depends_on = [module.aws_eks]
# }

# module "nginx_ingress" {
#   count            = var.create_eks && var.nginx_ingress_controller_enable ? 1 : 0
#   source           = "./kubernetes-addons/nginx-ingress"
#   nginx_helm_chart = var.nginx_helm_chart

#   depends_on = [module.aws_eks]
# }
