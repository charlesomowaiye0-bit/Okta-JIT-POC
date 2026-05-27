data "aws_ssoadmin_instances" "this" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]
  instance_arn      = data.aws_ssoadmin_instances.this.arns[0]

  inline_policies = compact([
    var.inline_policy,
    var.access_restricted_ssm ? null : data.aws_iam_policy_document.deny_restricted[0].json
  ])
}

# Merge caller-supplied inline_policy + the deny_restricted policy into one document.
# (AWS SSO permits exactly one inline policy per permission set.)
data "aws_iam_policy_document" "merged_inline" {
  count                   = length(local.inline_policies) > 0 ? 1 : 0
  source_policy_documents = local.inline_policies
}

data "aws_iam_policy_document" "deny_restricted" {
  count = var.access_restricted_ssm ? 0 : 1

  statement {
    sid       = "PathDeny"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["arn:aws:ssm:*:*:parameter/restricted/*"]
  }
}