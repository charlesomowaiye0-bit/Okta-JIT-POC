module "janitor_lambda" {
  source = "../../modules/aws/lambda"

  function_name = "jit-janitor"
  description   = "Revokes JIT grants on EventBridge Scheduler trigger."
  env           = "jit-poc"
  github_repo   = var.github_repo

  image_uri = "${data.aws_ecr_repository.janitor.repository_url}:bootstrap"

  architectures = ["arm64"]
  timeout       = 30
  memory_size   = 256

  environment_variables = {
    GRANTS_TABLE_NAME = data.aws_dynamodb_table.grants.name
  }

  policy_arns = {
    revoke = aws_iam_policy.janitor_revoke.arn
  }

  allowed_triggers = {
    scheduler = {
      service    = "scheduler"
      source_arn = "arn:aws:scheduler:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:schedule/jit-grants/*"
    }
  }
}
