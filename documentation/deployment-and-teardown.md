# 🚢 Deployment and teardown

Architecture, the technical decisions behind it, and the actual steps to
stand it up and take it back down.

## 🏛 Architecture at a glance

Two halves with a single seam.

The infrastructure half lives in `infra/` and is owned by Terraform. It
provisions the AWS resources the POC runs on: an IAM Identity Center
permission set, a DynamoDB grants table, the S3 and Secrets Manager
targets the portal grants access into, the ECR repositories the app
images live in, the ECS Express service the portal runs on, the
Janitor Lambda, and the EventBridge Scheduler group it consumes. Okta
is also managed as code here.

The application half lives in `app/` and is owned by the app pipeline.
It builds two container images, pushes them to ECR, and tells the
infra side to roll them out.

The two halves meet at SSM Parameter Store. `app-ci` writes
`/jit/app/image_tag` after a successful image push and dispatches
`infra-apply` to update the running services. The infra side never
builds images; the app side never runs `terraform apply`.

## 🐳 Why ECS Express for the portal

This is a POC. We wanted a managed way to ship a single container and
get HTTPS, networking, autoscaling, and a hostname without writing any
of it ourselves. ECS Express is AWS's "I just want to run a container,
deal with the rest" tier on top of ECS/Fargate, similar in spirit to
AWS App Runner or EKS auto mode. You pass an image and a task role,
and AWS handles the VPC plumbing, the gateway and certificate, and
autoscaling.

The trade-offs:

- The container has to be `linux/amd64`. arm64 isn't supported.
- A default VPC has to exist in the working region; Express won't
  build one for you.
- The auto-provisioned hostname (`*.ecs.<region>.on.aws`) can't be
  swapped for a custom domain without leaving Express behind.
- Destroys are slow and usually need a second pass.

A hand-rolled Fargate service with its own ALB would have given those
knobs back, but the incremental work didn't justify it for a POC. If
this graduated to production, the portal would move to Fargate behind
an internal-scheme ALB and a corporate domain.

## ⏰ Why Lambda plus EventBridge Scheduler for the Janitor

The Janitor is small, scheduled, and single-purpose: read a grant,
mutate a resource policy, update a row. It has no steady-state load
between firings, so a long-running container would burn money for no
reason. Lambda is the obvious shape.

We use EventBridge Scheduler as the trigger. When the portal approves
a grant, it creates a one-shot schedule pointed at the Janitor with
the `grant_id` baked into the payload. The schedule fires once at
expiry, the Janitor runs, and the schedule self-deletes via
`ActionAfterCompletion: DELETE`.

We picked EventBridge Scheduler over a periodic sweep because each
grant ends up with its own firing time, scheduled at the exact moment
revoke needs to happen. No periodic scan over the table asking "who's
expired," no risk of missing a window because a sweep ran late, no
queue to manage. Native AWS, serverless, and the Lambda + IAM wiring
is one step.

Capacity also stops being a question. EventBridge Scheduler supports
up to a million schedules per account by default, and each grant gets
its own entry. Hundreds of concurrent JIT grants in flight don't need
tuning, batching, or a queue in front of anything; the service
absorbs them.

One thing worth flagging: the first deploy of the Janitor needs a
placeholder image in ECR or `lambda:CreateFunction` rejects the apply.
The `seed-images` job in `infra-apply` handles that. Full write-up in
[`quirks.md`](quirks.md).

## 📒 Why DynamoDB for the grants table

The grants table is the audit ledger. Every request, every approval,
every revocation, including the justification and the ticket
reference, gets a row that's kept forever. PITR is on so we can
recover from operator error.

The access pattern is what DynamoDB serves cheaply. The Janitor reads
grants by `grant_id`, which is a single-item lookup. The portal's
"my access" page reads by `user_email`, served by a GSI. After
creation, the only writes are status flips on revoke. None of this
needs joins or scans, and DynamoDB's pricing rewards exactly that.

TTL is deliberately not enabled. Grants don't disappear; their status
flips to `revoked`. That's what makes the table useful as a ledger
later.

It also scales without anyone having to think about it. DynamoDB in
on-demand mode handles thousands of writes a second out of the box,
so the table doesn't become the bottleneck when a team goes from a
handful of grants per day to hundreds of concurrent requests. We
don't have to provision capacity, predict spikes, or stage growth.
The table absorbs whatever the portal throws at it.

## 🪣🔑 Why S3 and Secrets Manager as the first target types

Two target types, picked to validate the `Target` abstraction in
`app/shared/targets/`. S3 buckets and Secrets Manager secrets both
expose a resource policy that can be mutated to add or remove
`Sid: jit-<grant_id>` statements. Neither requires a CMK, neither
requires a VPC, and neither needs a separate identity provider in the
loop. Adding RDS or SQS later is a new `Target` implementation, not a
rearchitecture.

## 📤 Deployment flow

1. Run `scripts/check-prereqs.sh`. Verifies local tooling and that
   the AWS account has the permissions, IDC, and default VPC the POC
   expects.
2. Run `scripts/setup.sh`. Prompts for an email and name, writes them
   to `infra/identity.yaml`, idempotently creates the GitHub OIDC
   provider, and applies `infra/bootstrap/` against local state.
3. `git push` so the GHA workflow plans against the committed
   `identity.yaml`, not your working tree.
4. Dispatch `infra-apply` with all four boxes ticked (`aws_base`,
   `okta`, `janitor`, `jit_frontend`). The workflow applies them in
   dependency order and seeds `:bootstrap` ECR tags so
   `lambda:CreateFunction` and the ECS task def have something to
   point at.
5. Dispatch `app-ci`. It builds the real Streamlit and Janitor
   images, pushes them to ECR, and re-dispatches `infra-apply` for
   the two app stacks so the services pick up the new images.
6. Click through the AWS Identity Center invitation email and the
   Okta invitation email. Without SCIM or SAML, both have to happen
   by hand. See [`quirks.md`](quirks.md).
7. Open the Streamlit URL from the `apply-jit-frontend` run summary
   and log in.

## 🧹 Teardown flow

1. Dispatch `infra-destroy` with all four boxes ticked. The workflow
   tears down `aws-app/jit-frontend`, `aws-app/janitor`, `okta`, and
   `aws-base` in reverse dependency order, and empties the ECR repos
   before `aws-base` runs.
2. Run `infra/bootstrap/cleanup.sh` locally. Destroys the bootstrap
   stack (state bucket, lock table, OIDC roles, Okta token secret)
   and clears `bootstrap-outputs.json`.

ECS Express destroys are slow and usually need a second pass; the
first attempt often hangs and times out without finishing. Allow for
teardown to take longer than the apply did, and check
[`quirks.md`](quirks.md) if anything looks stuck.
