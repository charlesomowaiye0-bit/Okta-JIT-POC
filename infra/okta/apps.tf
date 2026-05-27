resource "okta_app_bookmark" "aws_access_portal" {
  label = "AWS Access Portal"
  url   = data.aws_ssm_parameter.aws_start_url.value
}

resource "okta_app_group_assignment" "jit_requesters_to_aws" {
  app_id   = okta_app_bookmark.aws_access_portal.id
  group_id = okta_group.this["jit-requesters"].id
}
