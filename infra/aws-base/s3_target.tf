resource "random_id" "s3_target_suffix" {
  byte_length = 4
}

module "s3_target" {
  source = "../modules/aws/s3"

  bucket_name              = "my-very-secret-bucket-that-holds-secret-files-${random_id.s3_target_suffix.hex}"
  description              = "Confidential demo files. JIT grants are statements in this bucket's policy."
  versioning_enabled       = true
  enforce_secure_transport = true
  generate_access_policies = false
  force_destroy            = true

  tags = {
    JIT            = "true"
    purpose        = "jit-target"
    classification = "confidential"
  }
}

resource "aws_s3_object" "test_objects" {
  for_each = {
    "compensation/2026.csv"  = "name,salary\nalice,150000\nbob,180000\n"
    "secrets/prod-creds.txt" = "REDACTED-DEMO\n"
  }
  bucket  = module.s3_target.bucket_id
  key     = each.key
  content = each.value
}
