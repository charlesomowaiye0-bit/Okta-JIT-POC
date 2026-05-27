# Okta stack

Manages Okta-as-code: users (sourced from [`../identity.yaml`](../identity.yaml)), groups, group rules, the AWS Access Portal bookmark tile, and the sign-on policy. SAML federation and SCIM provisioning between Okta and AWS Identity Center are a future enhancement; see [`../../documentation/quirks.md`](../../documentation/quirks.md) under "No SCIM, no SAML".

## Apply

Applied by the `infra-apply` workflow under the deployer OIDC role. See [`../README.md`](../README.md) for the workflow walkthrough.

## Destroy

Destroyed by the `infra-destroy` workflow. See [`../README.md`](../README.md#how-teardown-happens).
