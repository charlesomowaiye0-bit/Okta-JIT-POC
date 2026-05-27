# Infrastructure

This is the infrastructure directory. It houses Terraform resources for the
JIT-as-a-Pipeline POC.

## Stacks

### bootstrap

Foundational resources every other stack depends on: the S3 state bucket,
the DynamoDB lock table, the GitHub OIDC provider, the deployer and planner
IAM roles, and the Okta API token secret. This is the only stack applied
from a laptop. Its resources are singletons, and they have to exist before
any other stack can `terraform init`, which means they can't bootstrap
themselves from inside CI.

See [`bootstrap/README.md`](bootstrap/README.md) for what each file owns.

### aws-base

Truly shared AWS resources. The IAM Identity Center permission set used by
the JIT requesters group, the DynamoDB grants table that records every
access decision the portal makes, the S3 and Secrets Manager target
resources the POC grants access into, and the ECR repositories the app
images get pushed to. App stacks discover their targets at runtime via
tags, so adding a new target type is an infra edit, not an app change.

See [`aws-base/README.md`](aws-base/README.md). Why these specific shared
resources and not others is covered in [`documentation/`](../documentation/).

### okta

The Okta side of identity. Groups, group rules that drive joiner/mover
lifecycle off `department` and `subteam` user attributes, the SAML/SCIM app
for AWS access, and the MFA sign-on policy. Users come from
[`identity.yaml`](identity.yaml) and land here as `okta_user` resources.

See [`okta/README.md`](okta/README.md).

### aws-app/janitor

Everything related to the Janitor. The Lambda that revokes expired grants,
its execution role, the EventBridge Scheduler group it consumes, and the
SSM parameter that lets the app pipeline swap the Lambda's container image
without going through Terraform.

See [`aws-app/janitor/README.md`](aws-app/janitor/README.md).

### aws-app/jit-frontend

The Streamlit portal the user sees. The ECS Express service, its
auto-managed AWS hostname, the task role scoped to write grants and mutate
target resource policies, and the SSM parameter that pins the current
container image.

See [`aws-app/jit-frontend/README.md`](aws-app/jit-frontend/README.md). The
choice of ECS Express over plain Fargate is in [`documentation/`](../documentation/).

## How applies happen

Bootstrap is applied locally. Its resources are singletons that all other
stacks depend on, and they have nowhere to put their state until bootstrap
has run, so the chicken-and-egg gets resolved on a laptop, once.

Everything below bootstrap is applied by the `infra-apply` GitHub Actions
workflow, either on a push to `main` that touches an infra path or by
manual dispatch from the Actions UI.

## How teardown happens

Mirrors the apply story in reverse: stacks come down via the
`infra-destroy` workflow under the deployer OIDC role, then bootstrap is
torn down locally.

1. Open `infra-destroy`, click "Run workflow", tick all four boxes
   (`aws_base`, `okta`, `janitor`, `jit_frontend`) for a full teardown.
   The workflow runs them in reverse dependency order and empties the
   ECR repos before tearing down `aws-base`.
2. Once it finishes, run `infra/bootstrap/cleanup.sh` locally to delete
   the state bucket, lock table, OIDC roles, and Okta secret — and to
   clear the cached `bootstrap-outputs.json`.

## Shared

- [`modules/`](modules/) — the Terraform modules this POC is built from.
  Reusable pieces for S3, IAM, ECR, Lambda, Secrets Manager, EventBridge,
  DynamoDB, and an IDC permission-set module.
- [`policies/`](policies/) — Rego rules enforced by `conftest` at plan time.
  These are the IaC policy gates the pipeline runs before any infra change
  merges.
- [`identity.yaml`](identity.yaml) — the source of truth for users and group
  memberships. Both `okta/` and `aws-base/` read it; edits propagate to Okta
  and AWS Identity Center on the next apply.
