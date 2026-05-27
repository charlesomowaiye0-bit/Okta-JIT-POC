# Quirks and gotchas

Things that bit us while building this POC. The code shows what; this file
covers why.

## Bootstrap

### The state backend has to bootstrap itself locally

The bootstrap stack creates the S3 state bucket and the DynamoDB lock
table that every other stack uses for state. There's no place for
bootstrap to store its own state in a backend that doesn't exist yet, so
it runs with local state. `terraform.tfstate` lives on disk in
`infra/bootstrap/` until you run `infra/bootstrap/cleanup.sh`. Everything
else has remote state in the bucket bootstrap created.

### The GitHub OIDC provider is an AWS account singleton

You can have exactly one `token.actions.githubusercontent.com` OIDC
provider per AWS account. If you've already created one for another
project, bootstrap will fail trying to re-create it. `setup.sh` works
around this with a check-then-create pattern: it looks up the provider
ARN and only creates the resource if it isn't already there.

## Lambda images

### Lambda doesn't support GHCR, Docker Hub, or ECR Public

Lambda will only pull container images from ECR Private. We tried to
shortcut the "seed image" problem by pushing a placeholder to GHCR; it
fails at `lambda:CreateFunction` with `InvalidParameterValueException`.
The placeholder has to live in ECR Private in the same region as the
function. Cross-account works (with the right repository policy), but
cross-region does not.

### `lambda:CreateFunction` rejects a missing image

Terraform can't push a Docker image, but it can call
`lambda:CreateFunction`, which requires the image referenced by
`image_uri` to already exist in ECR. On a fresh account, the ECR repo
aws-base creates is empty, so the first apply of `aws-app/janitor` would
fail. The `seed-images` job in `infra-apply` pushes a `:bootstrap`
placeholder before the janitor stack runs. `app-ci` overwrites it on the
first real build.

### `lifecycle.ignore_changes = [image_uri]` on the Lambda

Once `app-ci` is replacing the Lambda's image via
`lambda:UpdateFunctionCode` (out-of-band from Terraform), a naive
`terraform plan` would diff the function back to the `:bootstrap` tag
on every run. The Lambda module pins
`lifecycle.ignore_changes = [image_uri]` so the CD path can update the
image without TF planning to undo it.

### Arm64 Lambda builds need QEMU on amd64 runners

The Janitor Lambda is arm64. GitHub Actions' default Ubuntu runners are
amd64, so `infra-apply` adds `docker/setup-qemu-action@v3` before the
seed step to let buildx cross-compile.

## ECS Express

### Express Mode is amd64 only

Unlike normal Fargate (which supports arm64), the ECS Express service
type does not. The Streamlit container has to be built `linux/amd64`.
The Janitor Lambda is happy on arm64 and stays there for the cost
savings.

### Express requires a default VPC

Express Mode uses the default VPC's subnets and security groups. If the
working region doesn't have a default VPC (commonly the case in
hardened accounts), the apply fails without a useful error.
`check-prereqs.sh` verifies the default VPC exists up front so the
failure happens early with a clear message instead of mid-apply.

### Express auto-provisions a hostname, no ALB

AWS provisions the hostname at
`https://<service-name>-<hash>.ecs.<region>.on.aws/`. The hash is
generated per-service and isn't known until the service is up, so we
can't print the URL up front. The `infra-apply` run summary links into
the ECS console where you can fish out the live URL. The trade-off is
no Route 53, no certificate, and no DNS record to manage, but also no
way to put it behind a custom domain without re-architecting away from
Express.

## Identity

### No SCIM, no SAML, so manual invitation acceptance

The POC seeds users into both Okta and AWS Identity Center from the
same `identity.yaml`, but it does not federate Okta as the IdP for AWS
Identity Center, and it does not SCIM-provision Okta into IDC. After
bootstrap, you'll receive two invitation emails, one from AWS Identity
Center and one from Okta. You have to click through both before you
can log into the portal.

### `identity.yaml` is the source of truth

Both `okta/` and `aws-base/` stacks read `infra/identity.yaml` at plan
time. Editing a user in one stack's TF but not the other will drift
the two sides apart fast. Do all user edits in `identity.yaml` and let
both stacks pick the change up on the next apply.

### Okta API token from Secrets Manager, not env

The Okta provider reads its API token from a Secrets Manager data
source rather than from `TF_VAR_okta_api_token` in CI env. Bootstrap
writes the token to Secrets Manager once; subsequent applies read it
via `data.aws_secretsmanager_secret_version`. Same pattern we use for
other provider credentials, and it keeps the token out of GitHub
Actions secrets.

## Teardown

### ECS Express services are slow to destroy and usually need a second pass

You'll probably have to run the destroy twice. The Express service hangs
for several minutes and tends to time out before the underlying
resources actually go away. Re-dispatching `infra-destroy` finishes the
job. Teardown takes longer than the apply did, and the first attempt
looking stuck is normal.

### Express destroys leave orphan target groups and task definitions

After `infra-destroy` finishes, the target group the Express service
sat behind is sometimes still in the account, unattached to any load
balancer. The ECS task definitions also stick around; task defs are
versioned, and AWS keeps every revision unless you explicitly
deregister it. Neither costs anything meaningful, but both show up in
the console looking like leftover state. Manual cleanup is one
`aws elbv2 delete-target-group` per orphan and a loop over
`aws ecs deregister-task-definition` against the `ACTIVE` revisions.

### Terraform destroy races on IAM and DynamoDB

IAM role detachments and DynamoDB table deletions occasionally race
against dependent resources (a Lambda still holding an execution role, a
schedule still attached to a target), and Terraform reports
`DeleteConflict` or similar. `infra-destroy` doesn't auto-retry. If you
see one of these, re-dispatch the workflow; the second pass usually
clears it.

### The `:bootstrap` ECR tag is never pruned

Once `app-ci` has pushed real images to ECR, the `:bootstrap` tag is
still there, pointing at the original placeholder. Nothing references
it anymore, but nothing deletes it either. A production version of
this would have an ECR lifecycle policy to expire stale tags. In the
POC, it just sits.

## Audit and cost

### DynamoDB has no TTL on grants

The grants table is the permanent audit ledger; rows are never
deleted, even after the grant is revoked. PITR is on. For a real
deployment with significant request volume this would balloon, and the
right answer is a tiered archive (hot rows in DDB, cold rows in S3 +
Athena). For the POC, the cost is negligible.
