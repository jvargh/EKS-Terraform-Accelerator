data "aws_iam_policy_document" "aws_s3" {
  statement {
    sid       = "ListObjectsInBucket"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.s3_bucket_name}"]
    actions   = ["s3:ListBucket"]
  }
  statement {
    sid       = "AllObjectActions"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
    actions   = ["s3:*Object"]
  }
}
