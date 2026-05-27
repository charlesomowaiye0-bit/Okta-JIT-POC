# aws-base stack

Truly shared resources — anything both apps depend on.

## What it creates

- **IDC `TF-AWS-JIT-Requesters`** permission set, assigned to the Okta `jit-requesters` group.
- **`jit-grants`** DynamoDB table (PITR on, GSI `user_email_index`, no TTL).
- **S3 target** bucket + demo files, tagged `JIT = "true"`.
- **`prod/my-very-sensitive-secret`** Secrets Manager target, tagged `JIT = "true"`.

App stacks (`aws-app/janitor`, `aws-app/jit-frontend`) discover JIT targets at runtime via tag-based queries (ABAC).

## Apply

Applied by the `infra-apply` workflow under the deployer OIDC role. See [`../README.md`](../README.md) for the workflow walkthrough.

## Destroy

Destroyed by the `infra-destroy` workflow. See [`../README.md`](../README.md#how-teardown-happens).
