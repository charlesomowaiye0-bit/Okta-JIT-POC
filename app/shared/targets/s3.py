from __future__ import annotations
import json
import boto3
from botocore.exceptions import ClientError


def _sid(gid: str) -> str: return f"jit{gid}"


class S3Target:
    target_type = "s3"

    def __init__(self, bucket_name: str, *, client=None):
        self.bucket_name = bucket_name
        self.target_arn = f"arn:aws:s3:::{bucket_name}"
        self._s3 = client or boto3.client("s3")

    def _read(self) -> dict:
        try:
            return json.loads(self._s3.get_bucket_policy(Bucket=self.bucket_name)["Policy"])
        except ClientError as e:
            if e.response["Error"]["Code"] == "NoSuchBucketPolicy":
                return {"Version": "2012-10-17", "Statement": []}
            raise

    def _write(self, p: dict) -> None:
        if not p["Statement"]:
            try: self._s3.delete_bucket_policy(Bucket=self.bucket_name)
            except ClientError as e:
                if e.response["Error"]["Code"] != "NoSuchBucketPolicy": raise
        else:
            self._s3.put_bucket_policy(Bucket=self.bucket_name, Policy=json.dumps(p))

    def grant(self, principal_pattern: str, actions: list[str], grant_id: str) -> None:
        p = self._read()
        p["Statement"] = [s for s in p["Statement"] if s.get("Sid") != _sid(grant_id)]
        # Wildcards aren't allowed inside the assumed-role ARN principal; match via condition.
        account_id = principal_pattern.split(":")[4]
        p["Statement"].append({
            "Sid": _sid(grant_id),
            "Effect": "Allow",
            "Principal": {"AWS": account_id},
            "Action": actions,
            "Resource": [self.target_arn, f"{self.target_arn}/*"],
            "Condition": {"ArnLike": {"aws:PrincipalArn": principal_pattern}},
        })
        self._write(p)

    def revoke_by_grant_id(self, grant_id: str) -> None:
        p = self._read()
        p["Statement"] = [s for s in p["Statement"] if s.get("Sid") != _sid(grant_id)]
        self._write(p)
