output "lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

output "deployer_iam_role_arn" {
  value = aws_iam_role.deployer[*].arn
}

output "lambda_iam_role_arn" {
  value = aws_iam_role.lambda.arn
}