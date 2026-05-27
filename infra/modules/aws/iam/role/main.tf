locals {
  tags = merge({ Name = var.role_name }, var.tags)
}

data "aws_iam_policy_document" "assume_role" {
  count = var.principals != null ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = var.principals.type
      identifiers = var.principals.identifiers
    }
  }
}

data "aws_iam_policy" "managed" {
  for_each = toset(var.managed_policies)
  name     = each.value
}

resource "aws_iam_role" "this" {
  name                  = var.role_name
  path                  = var.path
  description           = var.description
  assume_role_policy    = var.assume_role_policy != null ? var.assume_role_policy : data.aws_iam_policy_document.assume_role[0].json
  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = data.aws_iam_policy.managed

  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "policy_arns" {
  count = length(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.policy_arns[count.index]
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.name
  policy = each.value
}
