import json
import boto3
import pytest
from moto import mock_aws
from app.shared.targets.s3 import S3Target


@pytest.fixture
def s3_bucket():
    with mock_aws():
        boto3.client("s3", region_name="us-east-1").create_bucket(Bucket="test-bucket")
        yield "test-bucket"


def _policy(bucket):
    c = boto3.client("s3", region_name="us-east-1")
    try:
        return json.loads(c.get_bucket_policy(Bucket=bucket)["Policy"])
    except c.exceptions.from_code("NoSuchBucketPolicy"):
        return {"Version": "2012-10-17", "Statement": []}


def test_grant_adds_sid(s3_bucket):
    S3Target(s3_bucket).grant("arn:aws:sts::123:assumed-role/X/u", ["s3:GetObject"], "g1")
    assert "jitg1" in [s["Sid"] for s in _policy(s3_bucket)["Statement"]]


def test_revoke_only_that_sid(s3_bucket):
    t = S3Target(s3_bucket)
    t.grant("arn:aws:sts::123:assumed-role/X/a", ["s3:GetObject"], "g1")
    t.grant("arn:aws:sts::123:assumed-role/X/b", ["s3:GetObject"], "g2")
    t.revoke_by_grant_id("g1")
    sids = [s["Sid"] for s in _policy(s3_bucket)["Statement"]]
    assert "jitg2" in sids and "jitg1" not in sids
