resource "random_id" "bucket_suffix" {
  byte_length = 4
}

module "tfstate_bucket" {
  source = "../modules/aws/s3"

  bucket_name              = "jit-tfstate-${random_id.bucket_suffix.hex}"
  description              = "Terraform state for the JIT POC."
  versioning_enabled       = true
  enforce_secure_transport = true
  generate_access_policies = false
  force_destroy            = true
  tags = {
    purpose = "terraform-state"
  }
}

module "tfstate_lock" {
  source = "../modules/aws/dynamodb"

  service                        = "jit"
  name                           = "tfstate-lock"
  attributes                     = [{ name = "LockID", type = "S" }]
  billing_mode                   = "PAY_PER_REQUEST"
  deletion_protection_enabled    = false
  point_in_time_recovery_enabled = false
  tags = {
    purpose = "terraform-state-lock"
  }
}

module "tf_plan_role" {
  source = "../modules/aws/iam/role"

  role_name          = "jit-aws-planner"
  description        = "Read-only TF plan role for PR checks (assumed via GitHub OIDC)."
  assume_role_policy = data.aws_iam_policy_document.tf_plan_trust.json
  policy_arns        = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

module "aws_deployer_role" {
  source = "../modules/aws/iam/role"

  role_name          = "jit_aws_deployer"
  description        = "TF apply + image push + SSM updates (assumed via GitHub OIDC from main branch only)."
  assume_role_policy = data.aws_iam_policy_document.aws_deployer_trust.json
  policy_arns        = ["arn:aws:iam::aws:policy/PowerUserAccess"]
  inline_policies = {
    iam-lifecycle = data.aws_iam_policy_document.aws_deployer_iam.json
  }
}

module "okta_api_token_secret" {
  source = "../modules/aws/secrets-manager"

  name                    = "/jit/okta/api-token"
  description             = "Okta API token + org URL. Read by Okta TF provider and Streamlit app."
  recovery_window_in_days = 0
  tags = {
    purpose = "okta-provider-auth"
  }
}

resource "aws_secretsmanager_secret_version" "okta" {
  secret_id = module.okta_api_token_secret.arn
  secret_string = jsonencode({
    org_url = var.okta_org_url
    token   = var.okta_api_token
  })
}
