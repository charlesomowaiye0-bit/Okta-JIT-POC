# 📖 Overview

## 🧨 The problem

Every cloud team has the same access problem, and most of them solve it
badly.

Engineers need access to production resources to do their jobs. Sometimes
it's to drop a file in an S3 bucket, sometimes to rotate a secret, sometimes
to drain a queue or debug a Lambda. The "official" path is usually a
ticket: ask the platform team, wait for a human to read it, wait for that
human to grant the access, then forget to revoke it when the engineer is
done.

What actually happens in practice is one of two things. Either the
permission gets added to the engineer's permanent group membership because
that's the path of least resistance, and now they have standing prod
access they need about 1% of the time. Or they share credentials with
someone who already has the access, and now nobody knows who actually did
what. Both are how cloud compromises start.

JIT access flips the model. Permissions are granted only when needed,
scoped to the specific resource, and removed when the timer ends. Standing
access stops being a thing you can lose to a stolen credential, because
there isn't any. The audit trail stops being scattered across ticket
systems, Slack threads, and CloudTrail, because every grant lands in one
ledger with the request, the justification, and the revocation timestamp.

## 🛠 What we built

A self-serve portal where engineers request access to specific AWS
resources for a bounded window. When the request clears the checks, the
system:

1. Mutates the target's resource policy to add a `Sid: jit-<grant_id>`
   statement allowing the requester's principal the specific actions they
   asked for.
2. Writes a row to the DynamoDB grants table with the request details,
   justification, and expiry.
3. Creates a one-shot EventBridge schedule that fires at expiry and
   triggers the Janitor Lambda.

When the schedule fires, EventBridge Scheduler invokes the Janitor Lambda
with the `grant_id` in the event payload. The Janitor is a small Lambda
whose only job is this revocation loop: it reads the grant row from
DynamoDB to recover the target ARN and the actions involved, removes the
`Sid: jit-<grant_id>` statement from the target's resource policy, and
writes back to DynamoDB with `status="revoked"`, a `revoked_at` timestamp,
and `reason="expired"`. The schedule self-deletes after firing
(`ActionAfterCompletion: DELETE`), so there's no orphaned schedule left
behind.

If the engineer finishes early, they revoke from the "My access" page in
the portal. That runs the same revocation flow immediately and tears down
the pending schedule on the way out.

The whole loop is ask → grant → use → revoke → audit, running inside an
AWS account with no agents, no proxies, and no shared credentials.

One caveat about the portal today: it doesn't run real SSO. Streamlit
uses an Okta client to pull everyone in the `jit-requesters` Okta group
(sourced from `infra/identity.yaml`, the same file that drives the AWS
permission set) and lets you pick any of them from a dropdown. So
"logging in" is closer to "choosing whose request you want to submit."
It kept the demo dependency-free; in production we'd put Okta SSO in
front of the portal so each user only requests for themselves. The
next-steps section below covers what that looks like.

## 🎯 Why JIT belongs in your least-privilege story

Standing permissions are the root of most cloud compromises. If a
credential gets stolen, the blast radius is everything that credential
has standing access to, which is usually orders of magnitude more than
the user actually needs in the moment. The classic least-privilege
advice ("only grant what's needed") doesn't survive contact with real
engineering work, because what's needed changes constantly and nobody
updates IAM in lockstep with their week.

JIT inverts the model. Default access is the empty set. Access only
exists during the window an engineer is actively using it, scoped to
the specific resource they're touching. A credential leaked outside a
grant window does nothing useful. A credential leaked inside a grant
window is boxed in to one resource and one short timeframe.

The audit story also gets honest. Every action against a target lines
up with a grant row that says "this person asked for this action on
this resource for this reason at this time," instead of you having to
spelunk through CloudTrail wondering why an IAM user with `s3:*`
touched the prod bucket at 2 AM on a Sunday.

## 🤖 Not just people

Nothing in the model assumes the requester is human. The portal is a
Streamlit page because that was the right shape for the POC, but the
underlying grant flow takes a principal ARN and a target. It doesn't
care whether that principal is a person, a service, or an agent.

In production, this is where you'd expose an API so services can
self-serve. A payment service that needs to pull a one-off file from a
partner's S3 export bucket once a week. A monitoring agent that needs
to read a sensitive secret to debug an alert. They request the grant,
get scoped access for the window they need, and the system revokes
when they're done. Same ledger, same `Sid: jit-<grant_id>` statement,
same Janitor.

The win is least-privilege all the way down. Services and agents run
with the bare minimum standing IAM and ask for the rest when they
actually need it, the same way the humans do. Nothing carries
permanent "just in case" access, human or service. A compromised
service role is bounded the same way a leaked human credential is.

## 🛡 Especially in the agent era

This matters more now than it did even a year ago. AI agents are
landing in production systems with the same permission story we've been
giving humans for a decade: a service account with broad standing IAM,
because that's what worked last time. The threat model isn't the same.
A prompt-injected agent, or a compromised MCP server sitting on a
production role, is a CVE class that wasn't on anyone's threat model two
years ago, and the blast radius is whatever that service account holds.

CVEs are landing faster and the impact is widening. The gap between
"the model got weird" and "data left the account" is one IAM check.
Anything exploitable needs to be guarded, and the cheapest guard is
not having the permission in the first place until it's actually
needed.

JIT does exactly that. The agent has nothing by default. When it needs
to read a file, it asks: for that file, for that action, for that
window. If something goes sideways inside the window, the blast radius
is one short, scoped grant. There's no standing `s3:*` waiting around
for the next exploit to find it.

## 🪣🔑 Why S3 and Secrets Manager as the first targets

Both are VPC-agnostic. S3 and Secrets Manager don't live inside a VPC,
which means the POC ships without a custom VPC, custom subnets, security
group rules, or a NAT gateway in the picture. We wanted to demonstrate
real grant + revoke against real production-shaped resources without
sinking a week into networking before the actual JIT logic existed.

Both also expose mutable resource policies. The grant shape is the same
for either: add a `Sid: jit-<grant_id>` statement on grant, remove it on
revoke. That same shape works for SNS, SQS, Lambda, KMS, ECR, API
Gateway, EventBridge, Glue Data Catalog, and basically every other
AWS-managed service that takes a resource policy.

Glue Data Catalog is the one we'd reach for first in practice. If your
data team needs JIT access to a specific schema or table for a one-off
debug or a backfill, the same resource-policy shape carves access out
at the database or table ARN level without anyone touching standing IAM
groups. Analytics teams wanting a time-bound read on a production
schema, ML engineers needing write access for a backfill, anything where
the access is narrow, short-lived, and needs an audit trail: this is
the scenario the resource-policy pattern keeps coming up against in
practice.

The `Target` abstraction in `app/shared/targets/` is two methods,
`grant` and `revoke`. Adding support for another resource type is one
new class.

For IAM-auth resources like RDS, the revoke path looks different
(`iam:DetachRolePolicy` instead of editing a resource policy), but the
abstraction still holds. That's also roadmap.

## 🐍 Why `uv` for Python tooling

`uv` is what we use to install Python dependencies. It's a fast,
Rust-based replacement for `pip` and friends. One binary, no virtualenv
to manage, no `requirements.txt` ritual. Faster than `pip`, fewer
surprises than `poetry`, and a one-step install for new contributors.

`scripts/setup_identity.py` and `scripts/check_identity.py` declare
their dependencies inline at the top of the file, so they run as
`./scripts/setup_identity.py` without anyone having to create a venv
first. That's the kind of friction we wanted to keep out of the
bootstrap path.

## ⚠️ Where the line is

This isn't a runtime authorization engine. The system mutates resource
policies at grant time and at revoke time; the AWS resource itself
enforces the policy from there. No sidecar, no proxy, no agent. The
boundary is the resource policy, and the audit trail is the grant
ledger.

It also doesn't replace your identity provider. Okta is the source of
truth for who can use the portal at all; AWS Identity Center is the
source of truth for baseline AWS access. JIT sits on top of both and
grants additional access for a bounded window. If your IdP says someone
can't authenticate, JIT has nothing to give them.

This is a POC, not a finished product. The next section walks through
what we'd add to close the gaps.

## 🛣 What we'd add next

A few concrete moves to take this from POC to something we'd run for
real.

**App-level SSO.** Replace the test-user selector with real Okta SSO in
front of the portal. Each session is tied to one identity, you can only
submit requests for yourself, and nothing about being a member of
`jit-requesters` lets you impersonate someone else.

**Two-party approval before grant.** Insert a reviewer between the
request and the resource-policy mutation. The shape is closer to a pull
request than a JIRA ticket: small, contextual, approved by someone with
the work in their head (usually the requester's manager, sometimes a
peer who knows the service in question). This is the change that mostly
removes the platform team from the request flow. Their job becomes
maintaining the JIT app itself, not gatekeeping every grant.

**Cross-team and tag-based authorization.** Today's checks are flat
(group membership, duration cap, justification length, MFA). With user
attributes flowing through the SSO layer above, we can write real
policy: "requesters in team X can grant access to resources tagged
`team=X`," or "secrets tagged `sensitivity=high` require dual approval
and a max duration of 30 minutes." This is also where a runtime policy
engine (OPA, Cedar) actually earns its keep.

**Multi-account promotion.** The POC is single-account by design. A
real deployment would promote dev → stage → prod across an AWS Org,
with stricter approval gates the closer to prod you get.

**SCIM and SAML federation.** Wire Okta as the SAML IdP for AWS Identity
Center and SCIM-provision users into IDC. Removes the manual "click two
invitation emails" step at bootstrap. Nice to have, not load-bearing for
the architecture.

For the sharp edges we already know about, see [`quirks.md`](quirks.md).
For the architecture in detail, see
[`deployment-and-teardown.md`](deployment-and-teardown.md).
