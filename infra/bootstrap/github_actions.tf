locals {
  repo_name = split("/", var.github_repo)[1]
}

resource "github_actions_variable" "state_bucket_name" {
  repository    = local.repo_name
  variable_name = "STATE_BUCKET_NAME"
  value         = module.tfstate_bucket.bucket_id
}

resource "github_actions_variable" "tf_plan_role_arn" {
  repository    = local.repo_name
  variable_name = "TF_PLAN_ROLE_ARN"
  value         = module.tf_plan_role.role_arn
}

resource "github_actions_variable" "aws_deployer_role_arn" {
  repository    = local.repo_name
  variable_name = "AWS_DEPLOYER_ROLE_ARN"
  value         = module.aws_deployer_role.role_arn
}
