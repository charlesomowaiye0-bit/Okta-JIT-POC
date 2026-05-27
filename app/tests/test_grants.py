from datetime import datetime, timezone, timedelta
from app.shared.grants import Grant, GrantStatus, write_grant, get_grant, query_active_for_user, mark_revoked


def _g(grant_id="g-1", **kw):
    now = datetime.now(timezone.utc)
    base = dict(
        grant_id=grant_id,
        user_email="alice@gmail.com",
        user_sso_principal_pattern="arn:aws:sts::123:assumed-role/AWSReservedSSO_TF-AWS-JIT-Requesters_X/alice@gmail.com",
        target_arn="arn:aws:s3:::demo",
        target_type="s3",
        actions=["s3:GetObject"],
        sid=f"jit-{grant_id}",
        schedule_arn="arn:aws:scheduler:us-east-1:123:schedule/jit-grants/jit-" + grant_id,
        status=GrantStatus.ACTIVE,
        requested_at=now,
        expires_at=now + timedelta(minutes=30),
        duration_minutes=30,
        justification="debugging incident SRE-1234, need read-only access",
    )
    base.update(kw)
    return Grant(**base)


def test_round_trip(ddb_table):
    write_grant(ddb_table, _g())
    g = get_grant(ddb_table, "g-1")
    assert g.user_email == "alice@gmail.com"
    assert g.status == GrantStatus.ACTIVE


def test_query_filters_expired(ddb_table):
    now = datetime.now(timezone.utc)
    write_grant(ddb_table, _g())
    write_grant(ddb_table, _g(grant_id="g-2", expires_at=now - timedelta(minutes=1)))
    rows = query_active_for_user(ddb_table, "alice@gmail.com")
    assert [r.grant_id for r in rows] == ["g-1"]


def test_mark_revoked(ddb_table):
    write_grant(ddb_table, _g())
    mark_revoked(ddb_table, "g-1", reason="expired")
    g = get_grant(ddb_table, "g-1")
    assert g.status == GrantStatus.REVOKED
    assert g.revocation_reason == "expired"
