output "bucket_id" {
  description = "Bucket name"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "read_write_policy_arn" {
  description = "ARN of the IAM policy granting read+write access to this bucket. Null when generate_access_policies = false."
  value       = var.generate_access_policies ? aws_iam_policy.rw[0].arn : null
}

output "read_only_policy_arn" {
  description = "ARN of the IAM policy granting read-only access to this bucket. Null when generate_access_policies = false."
  value       = var.generate_access_policies ? aws_iam_policy.ro[0].arn : null
}
