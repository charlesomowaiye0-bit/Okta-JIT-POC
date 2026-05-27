locals {
  table_name = join("-", compact([var.service, var.name]))
  tags       = merge({ Name = local.table_name }, var.tags)
}

module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name                           = local.table_name
  attributes                     = var.attributes
  hash_key                       = var.attributes[0].name
  range_key                      = var.range_key
  global_secondary_indexes       = var.global_secondary_indexes
  billing_mode                   = var.billing_mode
  read_capacity                  = var.read_capacity
  write_capacity                 = var.write_capacity
  ttl_enabled                    = var.ttl_enabled
  ttl_attribute_name             = var.ttl_attribute_name
  point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
  deletion_protection_enabled    = var.deletion_protection_enabled

  # AWS-managed encryption by default; pass kms_key_arn for BYOK
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = var.kms_key_arn

  tags = local.tags
}
