# Scripts

This is the scripts directory. It houses the bootstrap and quality-of-life
scripts that make the POC's lifecycle manageable. Teardown is handled by
the `infra-destroy` workflow plus `infra/bootstrap/cleanup.sh`, not by
anything in here.

## User-facing

### check-prereqs.sh

Preflight check. Verifies Terraform, AWS CLI, `jq`, `uv`, and `gh` (or a
`GITHUB_TOKEN`) are present, confirms the caller has the IAM actions
needed to apply bootstrap (via `iam:SimulatePrincipalPolicy`), and
confirms IAM Identity Center is on and a default VPC exists in the
working region. Exits non-zero with a clear "what's missing" message if
anything fails.

### setup.sh

This is the bootstrap orchestrator. It runs `check-prereqs.sh`, seeds
`infra/identity.yaml` via `setup_identity.py`, validates it via
`check_identity.py`, prompts for the GitHub repo and Okta inputs,
idempotently creates the GitHub OIDC provider, and applies the
`infra/bootstrap/` stack. It closes with a next-step block telling the
user to commit `identity.yaml` and dispatch the `infra-apply` workflow.

## Identity helpers

Called by `setup.sh`. Not usually run by hand.

- [`setup_identity.py`](setup_identity.py) — interactive prompt that
  writes a one-user `infra/identity.yaml` if the file doesn't already
  exist. Re-runs are a no-op.
- [`check_identity.py`](check_identity.py) — schema validator. Flags
  missing fields, empty users lists, and duplicate emails before
  terraform plan has to.

## CI helpers

Called by `.github/workflows/infra-apply.yml` during the `seed-images`
job. They sit out here as scripts (rather than inline workflow steps) so
the seeding logic stays testable and editable on its own.

- [`seed_janitor_bootstrap.sh`](seed_janitor_bootstrap.sh) — builds and
  pushes a placeholder arm64 Lambda image to `jit-janitor:bootstrap`. The
  handler returns HTTP 503; `lambda:CreateFunction` just needs a valid
  image manifest at the URI it'll point at.
- [`seed_streamlit_bootstrap.sh`](seed_streamlit_bootstrap.sh) — retags
  `public.ecr.aws/docker/library/nginx:1` (amd64) as
  `jit-streamlit:bootstrap` so the ECS task def has something to launch.
  The container won't serve Streamlit on port 8080; that's fine until
  `app-ci` pushes the real image.

Both seed scripts no-op if the `:bootstrap` tag is already present. Why
the placeholders exist at all is in
[`documentation/quirks.md`](../documentation/quirks.md).
