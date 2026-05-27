#!/usr/bin/env bash
set -euo pipefail

red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
need()  {
  local name="$1" cmd="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    red "✗ $name not found"; FAIL=1
  else
    green "✓ $name: $($cmd --version 2>&1 | head -n1)"
  fi
}

FAIL=0

echo "── Tooling ──"
need "Terraform" terraform
need "AWS CLI"   aws
need "jq"        jq
need "uv"        uv

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  green "✓ gh: $(gh --version | head -n1) (authenticated)"
elif [ -n "${GITHUB_TOKEN:-}" ]; then
  green "✓ GITHUB_TOKEN exported (gh CLI not required)"
else
  red "✗ neither gh (authenticated) nor GITHUB_TOKEN found"
  FAIL=1
fi

echo ""
echo "── AWS identity ──"
if ! ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null); then
  red "✗ AWS credentials not configured"
  FAIL=1
else
  green "✓ Caller: $ARN"

  echo ""
  echo "── AWS authorization (simulate-principal-policy) ──"
  ACTIONS=(
    s3:CreateBucket s3:PutBucketPolicy s3:PutBucketVersioning s3:PutBucketEncryption
    dynamodb:CreateTable
    iam:CreateRole iam:CreatePolicy iam:CreateOpenIDConnectProvider iam:AttachRolePolicy
    secretsmanager:CreateSecret
    ssm:PutParameter
    sso-admin:CreatePermissionSet sso-admin:ListInstances
  )
  DENIED=$(aws iam simulate-principal-policy \
    --policy-source-arn "$ARN" \
    --action-names "${ACTIONS[@]}" \
    --query 'EvaluationResults[?EvalDecision!=`allowed`].EvalActionName' \
    --output text 2>/dev/null || echo "ERROR")
  if [ "$DENIED" = "ERROR" ]; then
    red "✗ Could not run simulate-principal-policy (the role itself may lack iam:Simulate*)"
    FAIL=1
  elif [ -z "$DENIED" ]; then
    green "✓ All bootstrap permissions available"
  else
    red "✗ Denied actions: $DENIED"
    FAIL=1
  fi
fi

echo ""
echo "── AWS account state ──"
if aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text 2>/dev/null | grep -q '^arn'; then
  green "✓ IAM Identity Center enabled"
else
  red "✗ IAM Identity Center not enabled, AWS orgianization-enabled account required"
  FAIL=1
fi

if aws ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text 2>/dev/null | grep -q '^vpc-'; then
  green "✓ Default VPC present"
else
  red "✗ No default VPC in this region"
  FAIL=1
fi

echo ""
[ "$FAIL" -ne 0 ] && { red "Prereqs incomplete."; exit 1; }
green "All prerequisites satisfied."
