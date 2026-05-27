resource "okta_app_signon_policy" "aws_idc_mfa" {
  name        = "Require MFA for AWS IDC"
  description = "JIT requesters must satisfy MFA before SSO into AWS."
}

resource "okta_app_signon_policy_rule" "require_mfa" {
  policy_id       = okta_app_signon_policy.aws_idc_mfa.id
  name            = "Require MFA"
  access          = "ALLOW"
  factor_mode     = "2FA"
  groups_included = [okta_group.this["jit-requesters"].id]
}
