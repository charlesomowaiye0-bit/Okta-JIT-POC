locals {
  subteam_attr = okta_user_schema_property.subteam.index

  okta_group_rules = {
    jit-requesters    = { expr = "user.department == \"engineering\"", group = "jit-requesters" }
    team-developers   = { expr = "user.${local.subteam_attr} == \"developers\"", group = "team-developers" }
    team-data-science = { expr = "user.${local.subteam_attr} == \"data-science\"", group = "team-data-science" }
    team-platform     = { expr = "user.${local.subteam_attr} == \"platform\"", group = "team-platform" }
  }
}

resource "okta_group_rule" "this" {
  for_each          = local.okta_group_rules
  name              = "rule-${each.key}"
  status            = "ACTIVE"
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = each.value.expr
  group_assignments = [okta_group.this[each.value.group].id]
}
