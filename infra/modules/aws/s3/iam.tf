data "aws_iam_policy_document" "rw" {
  count = var.generate_access_policies ? 1 : 0

  statement {
    sid    = "ReadWriteObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }

  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
    ]
    resources = [aws_s3_bucket.this.arn]
  }
}

resource "aws_iam_policy" "rw" {
  count = var.generate_access_policies ? 1 : 0

  name        = "${var.bucket_name}-rw"
  description = var.description != null ? "Read/write access to s3://${var.bucket_name} — ${var.description}" : "Read/write access to s3://${var.bucket_name}"
  policy      = data.aws_iam_policy_document.rw[0].json
  tags        = local.tags
}

#------------------------------------------------------------------------------
# IAM — read-only policy
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "ro" {
  count = var.generate_access_policies ? 1 : 0

  statement {
    sid       = "ReadObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }

  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [aws_s3_bucket.this.arn]
  }
}

resource "aws_iam_policy" "ro" {
  count = var.generate_access_policies ? 1 : 0

  name        = "${var.bucket_name}-ro"
  description = var.description != null ? "Read-only access to s3://${var.bucket_name} — ${var.description}" : "Read-only access to s3://${var.bucket_name}"
  policy      = data.aws_iam_policy_document.ro[0].json
  tags        = local.tags
}
