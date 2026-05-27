variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy into."
}

variable "github_repo" {
  type        = string
  description = "GitHub repo, 'owner/repo'. Used to scope the OIDC trust policy."
}

variable "okta_org_url" {
  type        = string
  description = "Okta tenant URL, e.g. https://integrator-5647961.okta.com."
}

variable "okta_api_token" {
  type        = string
  sensitive   = true
  description = "Okta API token. Stored in Secrets Manager after this run."
}
