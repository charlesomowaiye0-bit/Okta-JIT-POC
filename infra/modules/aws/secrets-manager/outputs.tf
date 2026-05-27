output "arn" {
  description = "Secret ARN"
  value       = aws_secretsmanager_secret.this.arn
}

output "name" {
  description = "Secret name"
  value       = aws_secretsmanager_secret.this.name
}

output "read_policy_arn" {
  description = "ARN of the IAM policy granting read access to this secret"
  value       = aws_iam_policy.read.arn
}

output "write_policy_arn" {
  description = "ARN of the IAM policy granting write access to this secret"
  value       = aws_iam_policy.write.arn
}
