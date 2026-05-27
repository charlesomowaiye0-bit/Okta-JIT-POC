resource "random_id" "sm_suffix" {
  byte_length = 4
}

module "secrets_manager_target" {
  source = "../modules/aws/secrets-manager"

  name                    = "prod/my-very-sensitive-secret"
  description             = "JIT target. Resource policy is mutated per-grant."
  recovery_window_in_days = 0

  tags = {
    JIT            = "true"
    purpose        = "jit-target"
    classification = "confidential"
  }
}

resource "aws_secretsmanager_secret_version" "target" {
  secret_id = module.secrets_manager_target.arn
  secret_string = jsonencode({
    api_key = "demo-${random_id.sm_suffix.hex}"
    note    = "Granted JIT via PutResourcePolicy."
  })
}
