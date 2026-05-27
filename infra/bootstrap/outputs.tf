output "state_bucket_name" {
  value = module.tfstate_bucket.bucket_id
}

output "state_lock_table" {
  value = module.tfstate_lock.table_id
}

output "tf_plan_role_arn" {
  value = module.tf_plan_role.role_arn
}

output "aws_deployer_role_arn" {
  value = module.aws_deployer_role.role_arn
}

output "okta_secret_name" {
  value = module.okta_api_token_secret.name
}

output "okta_secret_arn" {
  value = module.okta_api_token_secret.arn
}

output "github_repo" {
  description = "owner/repo of the GH repository the github provider is authenticated against. Used by cleanup.sh to destroy the correct repo's Actions variables."
  value       = var.github_repo
}
