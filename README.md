# 🔐 JIT-as-a-Pipeline

A workflow for granting least-privilege access on demand. Engineers request
the permissions they need for a specific job, access is scoped to that job,
and it's revoked just in time. No operator sits in the middle approving
tickets.

Say a BI teammember needs to pull some objects from S3, a backend dev needs
to drain a stuck SQS queue, or an engineer needs to update a secret backing
a production service. They open the portal, ask for the access, get it for
the window they asked for, and the system pulls it back when the timer
ends.

And it isn't just for humans. Services and AI agents can use the same
flow. That matters more every quarter as production work moves to
autonomous agents.

For the full story (what we built, why, where the line is, what comes
next), see [`documentation/overview.md`](documentation/overview.md).

## 🚀 Quick start

🍴 **Fork the repo first.** Bootstrap scopes the OIDC trust and the Actions
variables to your fork; you can't run this against the upstream.

You'll need: Terraform, AWS CLI, `jq`, `uv`, `gh` (or `GITHUB_TOKEN`), AWS
credentials, IAM Identity Center enabled, and a default VPC in the working
region. The preflight script confirms you have the AWS permissions the
bootstrap actually needs.

```bash
./scripts/check-prereqs.sh   # validates tools + AWS state
./scripts/setup.sh            # bootstraps the only locally-applied stack
```

Everything else applies via the `infra-apply` GitHub Actions workflow
under an OIDC role. For the full walkthrough (architecture and the
step-by-step deploy), see
[`documentation/deployment-and-teardown.md`](documentation/deployment-and-teardown.md).

🧪 Strongly recommended: use a fresh or sandboxed AWS account that doesn't
hold any production services, plus a fresh developer or integrator tenant
at [developer.okta.com](https://developer.okta.com). This POC touches IAM
and IAM Identity Center, neither of which you want anywhere near
production.

🧹 Teardown: dispatch `infra-destroy`, then run `infra/bootstrap/cleanup.sh`.
Same doc as above covers the teardown step-by-step.

## 🗺 Repo map

```
infra/              Terraform stacks and Okta-as-code
app/                Streamlit portal and Janitor Lambda
scripts/            bootstrap and quality-of-life scripts
.github/workflows/  CI/CD pipeline
documentation/      overview, deployment-and-teardown, and quirks
```

Each top-level directory has its own README with the next level of detail.

## 🐛 Hit something weird?

If you run into something that isn't covered in
[`documentation/quirks.md`](documentation/quirks.md), **please open an
issue**. That file grows from real bumps, and a quick issue is the
easiest way to get a fix in or at least get a note added for the next
person.

Same goes for anything in the docs that's wrong, missing, or unclear:
**open an issue**, send a PR, or just tell us where the wall was. We'd
rather hear about it than have you bounce off in silence.
