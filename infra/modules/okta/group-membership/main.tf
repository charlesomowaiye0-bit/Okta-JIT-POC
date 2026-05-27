locals {
  user_groups = var.user_groups
  users_map   = { for user in data.okta_users.this.users : lower(user.email) => user.id }

  missing_users = {
    for group in local.user_groups : group.name => [
      for email in group.users : email
      if lookup(local.users_map, lower(email), null) == null
    ]
  }
}

data "okta_users" "this" {
  search {
    expression = "(status lt \"DEPROVISIONED\" or status gt \"DEPROVISIONED\")"
  }
}
data "okta_group" "this" {
  for_each = toset([for group in local.user_groups : group.name])
  name     = each.value
}

resource "okta_group_memberships" "this" {
  for_each = { for group in local.user_groups : group.name => group.users }

  track_all_users = var.track_all_users
  group_id        = data.okta_group.this[each.key].id
  users           = [for user in each.value : local.users_map[lower(user)]]

  lifecycle {
    precondition {
      condition     = length(local.missing_users[each.key]) == 0
      error_message = "The following users do not exist or are deprovisioned in Okta:\n- ${join("\n- ", local.missing_users[each.key])}"
    }
  }
}