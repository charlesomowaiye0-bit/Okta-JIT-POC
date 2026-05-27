from __future__ import annotations
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from enum import Enum
from typing import Optional
from boto3.dynamodb.conditions import Key


class GrantStatus(str, Enum):
    ACTIVE = "active"
    REVOKED = "revoked"


@dataclass
class Grant:
    grant_id: str
    user_email: str
    user_sso_principal_pattern: str
    target_arn: str
    target_type: str
    actions: list[str]
    sid: str
    schedule_arn: str
    status: GrantStatus
    requested_at: datetime
    expires_at: datetime
    duration_minutes: int
    justification: str
    ticket_ref: Optional[str] = None
    revoked_at: Optional[datetime] = None
    revocation_reason: Optional[str] = None

    def to_item(self) -> dict:
        d = asdict(self)
        d["requested_at"] = self.requested_at.isoformat()
        d["expires_at"]   = self.expires_at.isoformat()
        d["status"]       = self.status.value
        d["revoked_at"]   = self.revoked_at.isoformat() if self.revoked_at else None
        return {k: v for k, v in d.items() if v is not None}

    @classmethod
    def from_item(cls, it: dict) -> "Grant":
        return cls(
            grant_id=it["grant_id"],
            user_email=it["user_email"],
            user_sso_principal_pattern=it["user_sso_principal_pattern"],
            target_arn=it["target_arn"],
            target_type=it["target_type"],
            actions=it["actions"],
            sid=it["sid"],
            schedule_arn=it["schedule_arn"],
            status=GrantStatus(it["status"]),
            requested_at=datetime.fromisoformat(it["requested_at"]),
            expires_at=datetime.fromisoformat(it["expires_at"]),
            duration_minutes=int(it["duration_minutes"]),
            justification=it["justification"],
            ticket_ref=it.get("ticket_ref"),
            revoked_at=datetime.fromisoformat(it["revoked_at"]) if it.get("revoked_at") else None,
            revocation_reason=it.get("revocation_reason"),
        )


def write_grant(table, g: Grant) -> None:
    table.put_item(Item=g.to_item())


def get_grant(table, grant_id: str) -> Optional[Grant]:
    r = table.get_item(Key={"grant_id": grant_id})
    return Grant.from_item(r["Item"]) if "Item" in r else None


def query_active_for_user(table, user_email: str) -> list[Grant]:
    r = table.query(IndexName="user_email_index", KeyConditionExpression=Key("user_email").eq(user_email))
    now = datetime.now(timezone.utc).isoformat()
    return [
        Grant.from_item(it) for it in r.get("Items", [])
        if it.get("status") == "active" and it.get("expires_at", "") > now
    ]


def mark_revoked(table, grant_id: str, *, reason: str) -> None:
    table.update_item(
        Key={"grant_id": grant_id},
        UpdateExpression="SET #s = :revoked, revoked_at = :ts, revocation_reason = :reason",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":revoked": GrantStatus.REVOKED.value,
            ":ts": datetime.now(timezone.utc).isoformat(),
            ":reason": reason,
        },
    )
