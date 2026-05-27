data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_dynamodb_table" "grants" {
  name = "jit-grants"
}

data "aws_ecr_repository" "streamlit" {
  name = "jit-streamlit"
}

data "aws_lambda_function" "janitor" {
  function_name = "jit-janitor"
}

data "aws_iam_role" "janitor_invocation" {
  name = "jit-scheduler-invoke-janitor"
}

data "aws_secretsmanager_secret" "okta_token" {
  name = "/jit/okta/api-token"
}

data "aws_ssm_parameter" "image_tag" {
  name       = "/jit/jit-frontend/image_tag"
  depends_on = [aws_ssm_parameter.image_tag]
}

data "aws_ssm_parameter" "test_users" {
  name = "/jit/setup/test_users"
}

data "aws_iam_policy_document" "ecs_task_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_inline" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
    ]
    resources = [
      data.aws_dynamodb_table.grants.arn,
      "${data.aws_dynamodb_table.grants.arn}/index/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:PutResourcePolicy",
      "secretsmanager:DeleteResourcePolicy",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/JIT"
      values   = ["true"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["tag:GetResources"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.okta_token.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "scheduler:CreateSchedule",
      "scheduler:DeleteSchedule",
      "scheduler:GetSchedule",
    ]
    resources = ["arn:aws:scheduler:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:schedule/jit-grants/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [data.aws_iam_role.janitor_invocation.arn]
  }
}
