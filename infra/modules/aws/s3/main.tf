locals {
  tags = merge({ Name = var.bucket_name }, var.tags)

  default_lifecycle_rules = [{
    id                            = "noncurrent-version-cleanup"
    status                        = "Enabled"
    transition                    = null
    expiration                    = null
    noncurrent_version_transition = { noncurrent_days = 30, storage_class = "GLACIER_IR" }
    noncurrent_version_expiration = { noncurrent_days = 365 }
  }]

  supplied_lifecycle_rules = var.lifecycle_rules == null ? [] : [
    for r in var.lifecycle_rules : {
      id                            = r.id
      status                        = r.status
      transition                    = try(r.transition, null)
      expiration                    = try(r.expiration, null)
      noncurrent_version_transition = try(r.noncurrent_version_transition, null)
      noncurrent_version_expiration = try(r.noncurrent_version_expiration, null)
    }
  ]

  effective_lifecycle_rules = length(local.supplied_lifecycle_rules) > 0 ? local.supplied_lifecycle_rules : local.default_lifecycle_rules
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "bucket_policy" {
  count = var.enforce_secure_transport ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.enforce_secure_transport ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy[0].json
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(local.effective_lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = local.effective_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      filter {}

      dynamic "noncurrent_version_transition" {
        for_each = try(rule.value.noncurrent_version_transition, null) != null ? [rule.value.noncurrent_version_transition] : []
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_version_expiration, null) != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      dynamic "expiration" {
        for_each = try(rule.value.expiration, null) != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }

      dynamic "transition" {
        for_each = try(rule.value.transition, null) != null ? [rule.value.transition] : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }
}
