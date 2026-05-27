locals {
  tags          = merge({ Name = var.name }, var.tags)
  policy_prefix = replace(var.name, "/", "-")
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  description             = var.description
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_in_days

  tags = local.tags
}

#------------------------------------------------------------------------------
# IAM — read policy
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "read" {
  statement {
    sid    = "ReadSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_secretsmanager_secret.this.arn]
  }

  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      sid       = "DecryptWithCMK"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [var.kms_key_arn]
    }
  }
}

resource "aws_iam_policy" "read" {
  name        = "${local.policy_prefix}-secret-read"
  description = "Read access to secret ${var.name}"
  policy      = data.aws_iam_policy_document.read.json
  tags        = local.tags
}

#------------------------------------------------------------------------------
# IAM — write policy
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "write" {
  statement {
    sid    = "WriteSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret",
      "secretsmanager:DeleteSecret",
    ]
    resources = [aws_secretsmanager_secret.this.arn]
  }

  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      sid       = "EncryptWithCMK"
      effect    = "Allow"
      actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
      resources = [var.kms_key_arn]
    }
  }
}

resource "aws_iam_policy" "write" {
  name        = "${local.policy_prefix}-secret-write"
  description = "Write access to secret ${var.name}"
  policy      = data.aws_iam_policy_document.write.json
  tags        = local.tags
}
