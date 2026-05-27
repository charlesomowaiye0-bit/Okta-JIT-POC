from __future__ import annotations
import os
import logging
import boto3

from app.shared.grants import get_grant, mark_revoked, GrantStatus
from app.shared.targets import registry


log = logging.getLogger()
log.setLevel(logging.INFO)


def handle(event: dict, _ctx) -> dict:
    grant_id = event["grant_id"]
    log.info("janitor_invoked", extra={"grant_id": grant_id})

    table = boto3.resource("dynamodb").Table(os.environ["GRANTS_TABLE_NAME"])
    grant = get_grant(table, grant_id)
    if grant is None:
        return {"status": "not_found"}
    if grant.status != GrantStatus.ACTIVE:
        return {"status": "noop"}

    registry.from_grant_arn(grant.target_type, grant.target_arn).revoke_by_grant_id(grant_id)
    mark_revoked(table, grant_id, reason="expired")
    return {"status": "revoked", "grant_id": grant_id}
