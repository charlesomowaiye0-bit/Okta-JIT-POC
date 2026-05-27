variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "allow_lambda_pull" {
  description = "Attach a repository policy permitting the AWS Lambda service to pull images from this repo. Required when this repo backs a container-based Lambda."
  type        = bool
  default     = false
}
