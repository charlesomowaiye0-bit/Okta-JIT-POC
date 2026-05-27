locals {
  okta_groups = {
    jit-requesters    = "Engineers eligible to request JIT access."
    team-developers   = "Developers subteam."
    team-data-science = "Data science subteam."
    team-platform     = "Platform subteam."
  }
}

resource "okta_group" "this" {
  for_each    = local.okta_groups
  name        = each.key
  description = each.value
}
