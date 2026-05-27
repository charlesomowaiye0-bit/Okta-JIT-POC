variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region."
}

variable "github_repo" {
  type        = string
  description = "GitHub repo 'owner/repo'. Passed to the lambda module so it provisions its own deployer role for app-ci."
}
