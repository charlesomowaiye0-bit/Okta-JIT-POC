module "scheduler_key" {
  count   = var.create_kms_key ? 1 : 0
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"

  aliases     = ["scheduler/${var.name}"]
  description = "KMS key for ${var.name} scheduler"
  policy      = data.aws_iam_policy_document.kms_key_policy[0].json
  tags        = var.tags
}