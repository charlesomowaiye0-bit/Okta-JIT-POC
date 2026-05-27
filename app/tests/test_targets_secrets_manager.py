import json, boto3, pytest
from moto import mock_aws
from app.shared.targets.secrets_manager import SecretsManagerTarget


@pytest.fixture
def sm_arn():
    with mock_aws():
        r = boto3.client("secretsmanager", region_name="us-east-1").create_secret(Name="s", SecretString="x")
        yield r["ARN"]


def test_grant_then_revoke(sm_arn):
    t = SecretsManagerTarget(sm_arn)
    t.grant("arn:aws:sts::1:assumed-role/X/u", ["secretsmanager:GetSecretValue"], "g")
    t.revoke_by_grant_id("g")
    # No assert needed beyond "doesn't raise" — full policy round-trip is exercised in test_janitor.
