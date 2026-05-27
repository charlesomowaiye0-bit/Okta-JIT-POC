# aws-app/jit-frontend stack

The Streamlit JIT portal.

## Owns

- `jit-streamlit` ECR repo
- `jit-ecs-task` IAM role (Streamlit's runtime role; DDB writes, ABAC-gated target policy admin, scheduler CRUD, iam:PassRole on janitor invocation role, Okta secret read, ResourceGroupsTaggingAPI read).
- `jit-frontend` ECS Express Mode service (amd64, single container, public HTTPS URL via `*.ecs.<region>.on.aws`).
- `/jit/jit-frontend/image_tag` SSM param.

## Reads

Direct AWS data sources (no SSM intermediary): `data "aws_dynamodb_table"`, `data "aws_lambda_function"`, `data "aws_iam_role"`, `data "aws_secretsmanager_secret"`. Plus `/jit/setup/test_users` and `/jit/jit-frontend/image_tag` SSM params.

Targets are discovered by Streamlit at runtime via ResourceGroupsTaggingAPI on `JIT=true`.

## Apply

Applied by the `infra-apply` workflow under the deployer OIDC role. See [`../../README.md`](../../README.md) for the walkthrough.

Dependencies inside the workflow: `aws-base` (writes `/jit/setup/test_users` and `/jit/setup/aws_start_url`) and `seed-images` (pushes the `:bootstrap` Streamlit image so the ECS task def has something to launch).

## Destroy

Destroyed by the `infra-destroy` workflow. See [`../../README.md`](../../README.md#how-teardown-happens).
