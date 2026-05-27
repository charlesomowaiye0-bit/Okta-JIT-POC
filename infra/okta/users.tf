locals {
  identity_path = "${path.module}/../identity.yaml"
  identity      = yamldecode(file(local.identity_path))
}

resource "okta_user" "this" {
  for_each = { for u in local.identity.users : u.email => u }

  email      = each.value.email
  login      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
  department = try(each.value.department, "engineering")

  custom_profile_attributes = jsonencode({
    subteam = try(each.value.subteam, "developers")
  })

  depends_on = [okta_user_schema_property.subteam]
}

resource "okta_user_schema_property" "subteam" {
  index       = "subteam"
  title       = "Subteam"
  type        = "string"
  master      = "OKTA"
  scope       = "NONE"
  user_type   = "default"
  permissions = "READ_WRITE"
}
