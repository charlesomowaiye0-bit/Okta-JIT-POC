from __future__ import annotations
from app.shared.targets.base import Target
from app.shared.targets.s3 import S3Target
from app.shared.targets.secrets_manager import SecretsManagerTarget


_REGISTRY: dict[str, dict] = {
    "s3": {
        "label_prefix": "s3",
        "factory": lambda ident: S3Target(bucket_name=ident),
        "actions": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
    },
    "secretsmanager": {
        "label_prefix": "secretsmanager",
        "factory": lambda ident: SecretsManagerTarget(secret_arn=ident),
        "actions": ["secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue"],
    },
}


def types() -> list[str]:
    return list(_REGISTRY.keys())


def actions_for(target_type: str) -> list[str]:
    return _REGISTRY[target_type]["actions"]


def build(target_type: str, identifier: str) -> Target:
    return _REGISTRY[target_type]["factory"](identifier)


def from_grant_arn(target_type: str, target_arn: str) -> Target:
    if target_type == "s3":
        return build("s3", target_arn.split(":")[-1])
    if target_type == "secretsmanager":
        return build("secretsmanager", target_arn)
    raise ValueError(target_type)
