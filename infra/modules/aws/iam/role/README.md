# aws/iam/role

Creates an IAM role with optional managed policy attachments, direct ARN attachments, and inline policies.

## Usage

### Service role (e.g. EC2)

```hcl
module "role" {
  source = "path/to/modules/aws/iam/role"

  role_name = "my-ec2-role"

  principals = {
    type        = "Service"
    identifiers = ["ec2.amazonaws.com"]
  }

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]

  inline_policies = {
    s3-read = data.aws_iam_policy_document.s3_read.json
  }

  tags = local.default_tags
}
```

### Bring your own assume role policy

```hcl
module "role" {
  source = "path/to/modules/aws/iam/role"

  role_name          = "my-role"
  assume_role_policy = data.aws_iam_policy_document.custom_trust.json
  policy_arns        = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| role_name | IAM role name | string | - | yes |
| assume_role_policy | Raw JSON trust policy. Overrides principals. | string | null | one of |
| principals | Principal block for trust policy | object | null | one of |
| description | Role description | string | null | no |
| path | IAM path | string | `/` | no |
| max_session_duration | Session duration in seconds (3600–43200) | number | 3600 | no |
| force_detach_policies | Force-detach policies on destroy | bool | false | no |
| managed_policies | AWS managed policy names (looked up by name) | list(string) | [] | no |
| policy_arns | Policy ARNs to attach directly | list(string) | [] | no |
| inline_policies | Map of inline policy name → JSON document | map(string) | {} | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | IAM role ARN |
| role_name | IAM role name |
