locals {
  identity_path = "${path.module}/../identity.yaml"
  identity      = yamldecode(file(local.identity_path))

  members_by_group = {
    for group_name in distinct(flatten([for u in local.identity.users : u.groups])) :
    group_name => [
      for u in local.identity.users : {
        email   = u.email
        user_id = aws_identitystore_user.this[u.email].user_id
      } if contains(u.groups, group_name)
    ]
  }
}

resource "aws_identitystore_user" "this" {
  for_each          = { for u in local.identity.users : u.email => u }
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]
  display_name      = "${each.value.first_name} ${each.value.last_name}"
  user_name         = each.value.email

  name {
    given_name  = each.value.first_name
    family_name = each.value.last_name
  }

  emails {
    value   = each.value.email
    primary = true
  }
}

module "jit_requesters_permission_set" {
  source = "../modules/aws/iam/permission-set"

  permission_set_name = "TF-AWS-JIT-Requesters"
  description         = "Minimal AWS access. Resource-level access is granted JIT via target resource policies."
  session_duration    = "PT1H"
  inline_policy       = data.aws_iam_policy_document.jit_requesters_inline.json
  group_names         = ["jit-requesters"]
  account_ids         = [data.aws_caller_identity.current.account_id]
  members             = local.members_by_group
}

resource "aws_ssm_parameter" "aws_start_url" {
  name  = "/jit/setup/aws_start_url"
  type  = "String"
  value = "https://${data.aws_ssoadmin_instances.this.identity_store_ids[0]}.awsapps.com/start"
}

resource "aws_ssm_parameter" "test_users" {
  name  = "/jit/setup/test_users"
  type  = "String"
  value = join(",", [for u in local.identity.users : u.email])
}
