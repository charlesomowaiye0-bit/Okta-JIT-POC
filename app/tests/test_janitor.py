from datetime import datetime, timezone, timedelta
import boto3
import pytest
from moto import mock_aws
from app.shared.grants import Grant, GrantStatus, write_grant, get_grant, mark_revoked


@pytest.fixture
def world(monkeypatch):
    monkeypatch.setenv("GRANTS_TABLE_NAME", "jit-grants")
    with mock_aws():
        c = boto3.client("dynamodb", region_name="us-east-1")
        c.create_table(
            TableName="jit-grants",
            KeySchema=[{"AttributeName": "grant_id", "KeyType": "HASH"}],
            AttributeDefinitions=[
                {"AttributeName": "grant_id", "AttributeType": "S"},
                {"AttributeName": "user_email", "AttributeType": "S"},
            ],
            GlobalSecondaryIndexes=[{
                "IndexName": "user_email_index",
                "KeySchema": [{"AttributeName": "user_email", "KeyType": "HASH"}],
                "Projection": {"ProjectionType": "ALL"},
            }],
            BillingMode="PAY_PER_REQUEST",
        )
        boto3.client("s3", region_name="us-east-1").create_bucket(Bucket="jit-target-test")
        yield boto3.resource("dynamodb", region_name="us-east-1").Table("jit-grants")


def _seed(table):
    from app.shared.targets.s3 import S3Target
    now = datetime.now(timezone.utc)
    g = Grant(
        grant_id="g-x",
        user_email="alice@gmail.com",
        user_sso_principal_pattern="arn:aws:sts::123:assumed-role/X/alice@gmail.com",
        target_arn="arn:aws:s3:::jit-target-test",
        target_type="s3",
        actions=["s3:GetObject"],
        sid="jit-g-x",
        schedule_arn="arn:aws:scheduler:us-east-1:123:schedule/jit-grants/jit-g-x",
        status=GrantStatus.ACTIVE,
        requested_at=now,
        expires_at=now + timedelta(minutes=30),
        duration_minutes=30,
        justification="testing janitor end-to-end happy path",
    )
    write_grant(table, g)
    S3Target("jit-target-test").grant(g.user_sso_principal_pattern, g.actions, g.grant_id)
    return g


def test_active_grant_is_revoked(world):
    from app.lambdas.janitor.handler import handle
    g = _seed(world)
    handle({"grant_id": g.grant_id}, None)
    after = get_grant(world, g.grant_id)
    assert after.status == GrantStatus.REVOKED
    assert after.revocation_reason == "expired"


def test_already_revoked_is_noop(world):
    from app.lambdas.janitor.handler import handle
    g = _seed(world)
    mark_revoked(world, g.grant_id, reason="user_requested")
    handle({"grant_id": g.grant_id}, None)
    after = get_grant(world, g.grant_id)
    assert after.revocation_reason == "user_requested"
