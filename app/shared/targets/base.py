from __future__ import annotations
from typing import Protocol


class Target(Protocol):
    target_type: str
    target_arn: str

    def grant(self, principal_pattern: str, actions: list[str], grant_id: str) -> None: ...
    def revoke_by_grant_id(self, grant_id: str) -> None: ...
