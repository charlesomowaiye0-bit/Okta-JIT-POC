locals {
  role_name = "${var.name}-scheduler-role"
}

module "scheduler_role" {
  source = "../../iam/iam_role"

  role_name          = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy      = var.create_kms_key ? data.aws_iam_policy_document.scheduler_policy[0].json : ""
  policy_arns        = var.additional_policy_arns
  tags               = var.tags
}