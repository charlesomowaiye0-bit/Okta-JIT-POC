output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "ECR repository URL (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/<name>)"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.this.arn
}
