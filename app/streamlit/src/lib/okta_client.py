from __future__ import annotations
from dataclasses import dataclass
import httpx


@dataclass
class OktaUser:
    id: str
    email: str
    department: str | None
    subteam: str | None
    groups: list[str]
    mfa_verified: bool


class OktaClient:
    def __init__(self, org_url: str, api_token: str):
        self._c = httpx.Client(
            base_url=org_url.rstrip("/"),
            headers={"Authorization": f"SSWS {api_token}", "Accept": "application/json"},
            timeout=10.0,
        )

    def resolve(self, email: str) -> OktaUser:
        u = self._c.get(f"/api/v1/users/{email}").raise_for_status().json()
        gs = self._c.get(f"/api/v1/users/{u['id']}/groups").raise_for_status().json()
        fs = self._c.get(f"/api/v1/users/{u['id']}/factors").raise_for_status().json()
        return OktaUser(
            id=u["id"],
            email=u["profile"]["email"],
            department=u["profile"].get("department"),
            subteam=u["profile"].get("subteam"),
            groups=[g["profile"]["name"] for g in gs],
            mfa_verified=any(f.get("status") == "ACTIVE" for f in fs),
        )
