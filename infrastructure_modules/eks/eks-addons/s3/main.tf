/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

resource "aws_s3_bucket_policy" "s3_logs_bucket_policy" {
  bucket = aws_s3_bucket.s3_logs_bucket.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "ELBAccesLogsBucketPolicy",
    "Statement": [
      {
        "Sid": "AWSConsoleStmt1234",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${var.account_id}:root"
        },
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        "Sid": "AWSLogDeliveryWrite",
        "Effect": "Allow",
        "Principal": {
          "Service": "delivery.logs.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${var.s3_bucket_name}/*",
        "Condition": {
          "StringEquals": {
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        }
      },
      {
        "Sid": "AWSLogDeliveryAclCheck",
        "Effect": "Allow",
        "Principal": {
          "Service": "delivery.logs.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "arn:aws:s3:::${var.s3_bucket_name}"
      }
    ]
  }
POLICY
}

resource "aws_s3_bucket" "s3_logs_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = var.s3_bucket_name
  }
}

# IRSA 
module "irsa_addon" {
  source                      = "../irsa"
  eks_cluster_name            = var.cluster_id
  create_kubernetes_namespace = false
  kubernetes_namespace        = local.add_on_config["namespace"]
  kubernetes_service_account  = local.add_on_config["service_account"]
  irsa_iam_policies           = concat([aws_iam_policy.aws_s3.arn], local.add_on_config["additional_iam_policies"])
  tags                        = var.common_tags
}

resource "aws_iam_policy" "aws_s3" {
  description = "IAM Policy for AWS S3"
  name        = "${var.cluster_id}-${local.add_on_config["addon_name"]}-irsa"
  path        = var.iam_role_path
  policy      = data.aws_iam_policy_document.aws_s3.json
}

resource "kubernetes_secret" "vvp_sa_secret" {
  metadata {
    name      = local.add_on_config["secret_name"]
    namespace = local.add_on_config["namespace"]
    annotations = {
      "kubernetes.io/service-account.name" = local.add_on_config["service_account"]
    }
  }
  type       = "kubernetes.io/service-account-token"
  depends_on = [module.irsa_addon]
}
