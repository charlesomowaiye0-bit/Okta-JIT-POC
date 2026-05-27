# Bootstrap

Local-state stack run once with admin credentials. Creates the things every other stack assumes exist.

**Why local state:** this stack *creates* the S3 + DynamoDB backend that all other stacks use. It can't store state in a backend that doesn't exist yet. After bootstrap, `terraform.tfstate` lives here in this directory.

## What it creates

| Resource | Purpose |
|---|---|
| `jit-tfstate-<random>` (S3) | Terraform state bucket for all other stacks |
| `jit-tfstate-lock` (DynamoDB) | State locking |
| GitHub OIDC provider | Federation for CI/CD |
| `jit-aws-planner` IAM role | Read-only; assumed by PR plan jobs from any branch |
| `jit_aws_deployer` IAM role | Write; assumed by main-branch apply + image push + SSM updates |
| `/jit/okta/api-token` (Secrets Manager) | Okta provider auth for subsequent stacks |
| `STATE_BUCKET_NAME` (GitHub Actions var) | State bucket name; plumbed into the workflows' `-backend-config` |
| `TF_PLAN_ROLE_ARN` (GitHub Actions var) | OIDC role ARN assumed by plan jobs |
| `AWS_DEPLOYER_ROLE_ARN` (GitHub Actions var) | OIDC role ARN assumed by apply and destroy jobs |

## Apply

Driven by `../../setup.sh` (which prompts for the inputs). Direct apply:

```bash
terraform init
terraform apply \
  -var "github_repo=owner/repo" \
  -var "okta_org_url=https://integrator-XXXX.okta.com" \
  -var "okta_api_token=…"
```

## Destroy

Run `./cleanup.sh` after the `infra-destroy` workflow has finished tearing down the non-bootstrap stacks. It runs `terraform destroy`, removes the local state files, and clears `bootstrap-outputs.json` at the repo root so the directory can be re-initialized cleanly.
