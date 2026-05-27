output "table_id" {
  description = "Name/ID of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_id
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_arn
}

output "read_policy_arn" {
  description = "ARN of the IAM policy granting read access to the table"
  value       = aws_iam_policy.read.arn
}

output "write_policy_arn" {
  description = "ARN of the IAM policy granting write access to the table"
  value       = aws_iam_policy.write.arn
}
