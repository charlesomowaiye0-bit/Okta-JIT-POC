data "aws_caller_identity" "current" {
  count = var.allow_lambda_pull ? 1 : 0
}

data "aws_region" "current" {
  count = var.allow_lambda_pull ? 1 : 0
}
