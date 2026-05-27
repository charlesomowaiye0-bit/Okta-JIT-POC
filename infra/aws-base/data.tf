data "aws_caller_identity" "current" {}

data "aws_ssoadmin_instances" "this" {}

data "aws_iam_policy_document" "jit_requesters_inline" {
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity", "sso:GetSSOStatus"]
    resources = ["*"]
  }
}
