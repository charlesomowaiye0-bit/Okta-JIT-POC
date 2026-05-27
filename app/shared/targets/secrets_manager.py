from __future__ import annotations
import json
import boto3
from botocore.exceptions import ClientError


def _sid(gid: str) -> str: return f"jit{gid}"  # Secrets Manager Sid must be alphanumeric


class SecretsManagerTarget:
    target_type = "secretsmanager"

    def __init__(self, secret_arn: str, *, client=None):
        self.secret_arn = secret_arn
        self.target_arn = secret_arn
        self._sm = client or boto3.client("secretsmanager")

    def _read(self) -> dict:
        try:
            r = self._sm.get_resource_policy(SecretId=self.secret_arn).get("ResourcePolicy")
            if r: return json.loads(r)
        except ClientError as e:
            if e.response["Error"]["Code"] != "ResourceNotFoundException": raise
        return {"Version": "2012-10-17", "Statement": []}

    def _write(self, p: dict) -> None:
        if not p["Statement"]:
            try: self._sm.delete_resource_policy(SecretId=self.secret_arn)
            except ClientError as e:
                if e.response["Error"]["Code"] != "ResourceNotFoundException": raise
        else:
            self._sm.put_resource_policy(SecretId=self.secret_arn, ResourcePolicy=json.dumps(p))

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
            "Resource": self.secret_arn,
            "Condition": {"ArnLike": {"aws:PrincipalArn": principal_pattern}},
        })
        self._write(p)

    def revoke_by_grant_id(self, grant_id: str) -> None:
        p = self._read()
        p["Statement"] = [s for s in p["Statement"] if s.get("Sid") != _sid(grant_id)]
        self._write(p)
