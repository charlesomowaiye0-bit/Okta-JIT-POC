# Application

This is the application directory. It houses the application code for the
JIT-as-a-Pipeline POC.

## Components

### Frontend

The portal the user logs into. Code lives in [`streamlit/src/`](streamlit/src/):
`main.py` is the entrypoint. `pages/request_access.py` is the request form;
on submit it runs the checks, mutates the target's resource policy, and
creates the EventBridge schedule for the eventual revoke.
`pages/my_access.py` lists a user's active grants and exposes the
early-revoke button. `lib/` is the supporting code: an Okta client, the
request checks (group membership, duration cap, justification length, MFA),
and the helper that finds targets at runtime by their tags. Ships with a
`Dockerfile` and `pyproject.toml`; `app-ci` builds and pushes it to ECR as
`jit-streamlit:<sha>`.

### lambdas/janitor

The Janitor Lambda. One file, [`lambdas/janitor/handler.py`](lambdas/janitor/handler.py),
invoked by EventBridge Scheduler with a `grant_id` payload. Reads the
grant, calls `target.revoke()`, updates the grant row to `revoked`. Same
`app-ci` pipeline, pushed as `jit-janitor:<sha>`.

One quirk: the Janitor's `:bootstrap` image is seeded by `infra-apply`
before the Lambda is created, the same way the Streamlit `:bootstrap` tag
is seeded. `lambda:CreateFunction` api rejects missing image, so the
workflow pushes a placeholder; `app-ci` swaps in the real handler on the
first build. The detail and the reasoning live in
[`documentation/quirks.md`](../documentation/quirks.md).

### shared

The library both the portal and the Janitor import from.

- [`grants.py`](shared/grants.py) — DynamoDB CRUD for the grants table.
  The portal writes on grant creation; the Janitor reads and updates on
  revoke.
- [`targets/`](shared/targets/) — the `Target` protocol and its
  implementations. `base.py` defines the interface (`grant`, `revoke`),
  `s3.py` and `secrets_manager.py` are the concrete targets, and
  `registry.py` discovers them at runtime via the tags `aws-base/` puts on
  the underlying resources.

When a new resource type, policy shape, or audit field needs to land,
this is where it goes. Both consumers see the change as soon as they
import.

### tests

Pytest suite using `moto` to stub AWS. Covers `grants.py`, both target
implementations, the Okta client, and the Janitor handler's happy path.
Coverage is light: enough to catch the obvious regressions on the
critical paths, not enough to call this hardened. A real implementation
would push out into failure modes and property-based tests on the target
abstraction. What's here gets us over the bridge.

## How it gets built

The portal and the Janitor ship as independent container images.
They're operationally codependent: the portal creates grants, the
Janitor undoes them. `app-ci` builds each image and pushes both to ECR.

The rollout path differs by image. The frontend update goes through
`infra-apply` so the ECS task def picks up the new tag. The Janitor
update is a direct `aws lambda update-function-code` call, because the
Lambda module pins `lifecycle.ignore_changes = [image_uri]` so the CD
path can bypass Terraform.

On a fresh account, the first deploy lands with placeholder images in
both ECRs. The Janitor placeholder returns HTTP 503 on every invocation.
The Streamlit task launches an nginx container that doesn't serve on the
Streamlit port, so the portal URL doesn't load anything useful until the
real image arrives. The first `app-ci` run replaces both. Same story as
the bootstrap seeding, written up in
[`documentation/quirks.md`](../documentation/quirks.md).
