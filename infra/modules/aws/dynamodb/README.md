# dynamodb

Creates a DynamoDB table with AWS-managed encryption, PITR, and deletion protection on by default. Pass `kms_key_arn` to use your own KMS key (BYOK).

## Usage

```hcl
locals {
  config = yamldecode(file("${path.module}/config.yaml"))
}

module "fitness_logs" {
  source = "../../modules/aws/dynamodb"

  service     = "fitness"
  name        = "logs"
  environment = "prod"

  attributes = [
    { name = "user_id",   type = "S" },
    { name = "timestamp", type = "S" },
  ]

  tags = {
    ManagedBy = local.config.managedBy
    Account   = local.config.account
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| service | Service name (table name prefix) | string | - | yes |
| environment | Environment (dev, staging, prod) | string | - | yes |
| attributes | Attribute definitions. First = hash key, second = range key | list(object) | - | yes |
| name | Optional suffix for table name | string | `null` | no |
| billing_mode | PAY_PER_REQUEST or PROVISIONED | string | `PAY_PER_REQUEST` | no |
| read_capacity | Read capacity (PROVISIONED only) | number | `null` | no |
| write_capacity | Write capacity (PROVISIONED only) | number | `null` | no |
| ttl_enabled | Enable TTL | bool | `false` | no |
| ttl_attribute_name | TTL attribute name | string | `""` | no |
| deletion_protection_enabled | Prevent accidental deletion | bool | `true` | no |
| point_in_time_recovery_enabled | Enable PITR | bool | `true` | no |
| kms_key_arn | Custom KMS key ARN (BYOK). Defaults to AWS-managed. | string | `null` | no |
| tags | Additional tags | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| table_id | Name/ID of the DynamoDB table |
| table_arn | ARN of the DynamoDB table |
