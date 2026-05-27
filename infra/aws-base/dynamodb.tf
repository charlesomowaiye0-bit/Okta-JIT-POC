module "grants_table" {
  source = "../modules/aws/dynamodb"

  service = "jit"
  name    = "grants"

  attributes = [
    { name = "grant_id", type = "S" },
    { name = "user_email", type = "S" },
  ]

  billing_mode = "PAY_PER_REQUEST"

  global_secondary_indexes = [{
    name            = "user_email_index"
    hash_key        = "user_email"
    projection_type = "ALL"
  }]

  deletion_protection_enabled    = false # POC: cleanup.sh requires this.
  point_in_time_recovery_enabled = true

  tags = {
    purpose = "jit-audit-ledger"
  }
}
