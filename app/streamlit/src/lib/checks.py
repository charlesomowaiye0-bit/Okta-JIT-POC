from __future__ import annotations

from dataclasses import dataclass


# Per-target-type maximum duration in minutes. 6h cap.
MAX_DURATION_MINUTES = {
    "s3": 360,
    "secretsmanager": 360,
}


@dataclass
class CheckRequest:
    user_groups: list[str]
    mfa_verified: bool
    target_type: str
    actions: list[str]
    duration_minutes: int
    justification: str


@dataclass
class CheckResult:
    allow: bool
    reasons: list[str]


def evaluate(req: CheckRequest) -> CheckResult:
    reasons: list[str] = []

    if "jit-requesters" not in req.user_groups:
        reasons.append("user_not_in_jit_requesters")

    if len(req.justification.strip()) < 20:
        reasons.append("justification_too_short")

    if req.duration_minutes > MAX_DURATION_MINUTES.get(req.target_type, 60):
        reasons.append("duration_exceeds_max")

    if any("Put" in a for a in req.actions) and not req.mfa_verified:
        reasons.append("write_without_mfa")

    return CheckResult(allow=not reasons, reasons=reasons)
