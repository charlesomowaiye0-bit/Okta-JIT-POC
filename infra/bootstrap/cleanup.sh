#!/usr/bin/env bash
# Per-stack teardown. Called by the repo-root cleanup.sh, but also runnable on its own.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Bootstrap cleanup"

if [ ! -f "terraform.tfstate" ] && [ ! -d ".terraform" ]; then
  echo "    No local state found. Nothing to destroy."
else
  # github_repo is NOT a placeholder for destroy: the github provider's `owner`
  # is derived from it, and we need the DELETE calls to target the real repo
  # so the Actions variables actually get removed. Read it back from state.
  REAL_REPO=$(terraform output -raw github_repo 2>/dev/null || echo "placeholder/placeholder")
  terraform destroy -auto-approve \
    -var "github_repo=$REAL_REPO" \
    -var "okta_org_url=https://placeholder.okta.com" \
    -var "okta_api_token=placeholder"
fi

echo "    Removing local state + .terraform/"
rm -rf terraform.tfstate terraform.tfstate.backup .terraform .terraform.lock.hcl

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
rm -f "$REPO_ROOT/bootstrap-outputs.json"

echo "✓ Bootstrap directory clean."
