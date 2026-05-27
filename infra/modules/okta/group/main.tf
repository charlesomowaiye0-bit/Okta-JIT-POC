resource "okta_group" "this" {
  for_each    = toset(var.groups)
  name        = each.value
  description = "Okta group for ${each.value}, ManagedBy Terraform"
}

resource "okta_app_group_assignment" "this" {
  for_each          = toset(var.okta_app_id == null ? [] : var.groups)
  app_id            = var.okta_app_id
  group_id          = okta_group.this[each.value].id
  retain_assignment = var.retain_assignment
}