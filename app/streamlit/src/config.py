from __future__ import annotations
import os
import json
import boto3
from functools import cache


def grants_table_name() -> str:           return os.environ["GRANTS_TABLE_NAME"]
def scheduler_group() -> str:             return os.environ["SCHEDULER_GROUP"]
def janitor_lambda_arn() -> str:          return os.environ["JANITOR_LAMBDA_ARN"]
def janitor_invocation_role_arn() -> str: return os.environ["JANITOR_INVOCATION_ROLE_ARN"]
def aws_account_id() -> str:              return os.environ["AWS_ACCOUNT_ID"]
def principal_pattern_template() -> str:  return os.environ["PRINCIPAL_PATTERN_TEMPLATE"]


def test_users() -> list[str]:
    return [e.strip() for e in os.environ.get("TEST_USERS", "").split(",") if e.strip()]


def use_okta_sso() -> bool:
    return os.environ.get("USE_OKTA_SSO", "false").lower() == "true"


@cache
def _okta() -> tuple[str, str]:
    raw = boto3.client("secretsmanager").get_secret_value(SecretId=os.environ["OKTA_SECRET_NAME"])["SecretString"]
    p = json.loads(raw)
    return p["org_url"], p["token"]


def okta_org_url() -> str:   return _okta()[0]
def okta_api_token() -> str: return _okta()[1]


def principal_for(email: str) -> str:
    return principal_pattern_template().replace("{email}", email)
