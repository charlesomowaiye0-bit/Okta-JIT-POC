#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

./scripts/check-prereqs.sh
./scripts/setup_identity.py
./scripts/check_identity.py infra/identity.yaml

read -rp "GitHub repo (owner/repo): " GITHUB_REPO
echo "    Okta tenant URL — e.g., https://xxxxxx.okta.com... We suggest creating a test/integrator account at https://developer.okta.com"
read -rp "Okta org URL: " OKTA_ORG
read -rsp "Okta API token: " OKTA_TOKEN; echo

if [ -z "${GITHUB_TOKEN:-}" ]; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    export GITHUB_TOKEN="$(gh auth token)"
  else
    echo "    GitHub PAT (scopes: repo, admin:repo_hook)."
    read -rsp "GitHub token: " GITHUB_PAT; echo
    export GITHUB_TOKEN="$GITHUB_PAT"
  fi
fi

# Exported once so every `terraform` invocation (init, import, plan, apply) sees the same values.
export TF_VAR_github_repo="$GITHUB_REPO"
export TF_VAR_okta_org_url="$OKTA_ORG"
export TF_VAR_okta_api_token="$OKTA_TOKEN"

# GitHub OIDC provider is an account-singleton.
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
OIDC_ARN="arn:aws:iam::${ACCOUNT}:oidc-provider/token.actions.githubusercontent.com"
if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" >/dev/null 2>&1; then
  echo "==> Creating GitHub OIDC provider (none exists yet)"
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 >/dev/null
fi

pushd infra/bootstrap >/dev/null
terraform init -upgrade
terraform apply -auto-approve
terraform output -json > "$ROOT/bootstrap-outputs.json"
popd >/dev/null

GREEN=$'\033[32m'
NC=$'\033[0m'

printf '%s' "$GREEN"
echo ""
echo "✓ Bootstrap complete."
echo ""
echo "Next:"
echo "  1. Commit infra/identity.yaml and push to main:"
echo ""
echo "       git add infra/identity.yaml && git commit -m \"seed identity\" && git push"
echo ""
echo "  2. Open infra-apply, click 'Run workflow', tick all four boxes"
echo "     (aws_base, okta, janitor, jit_frontend) on the first run:"
echo ""
echo "       https://github.com/$GITHUB_REPO/actions/workflows/infra-apply.yml"
echo ""
echo "  3. After it finishes (~6-8 min), open app-ci and click 'Run workflow'"
echo "     to push the real images:"
echo ""
echo "       https://github.com/$GITHUB_REPO/actions/workflows/app-ci.yml"
echo ""
echo "  4. apply-jit-frontend's run summary links to the ECS console for the live Streamlit URL."
printf '%s' "$NC"
