import json
import uuid
import boto3
import streamlit as st
from datetime import datetime, timezone, timedelta

from app.streamlit.src import config
from app.streamlit.src.lib.okta_client import OktaClient
from app.streamlit.src.lib.checks import CheckRequest, evaluate
from app.streamlit.src.lib.target_discovery import discover_targets
from app.shared.grants import Grant, GrantStatus, write_grant
from app.shared.targets import registry


st.title("Request access")

if config.use_okta_sso():
    st.error("Okta SSO not wired yet (see spec §13).")
    st.stop()

users = config.test_users()
if not users:
    st.warning("No test users configured. See instructions on Adding users to OKTA")
    st.stop()

user_email = st.selectbox("Acting as", users)

okta = OktaClient(config.okta_org_url(), config.okta_api_token())
try:
    user = okta.resolve(user_email)
except Exception as e:
    st.error(f"Okta lookup failed: {e}")
    st.stop()
st.caption(f"Groups: {', '.join(user.groups)} | MFA: {'✓' if user.mfa_verified else '✗'}")

targets_by_type = discover_targets()
target_type = st.radio(
    "Resource type",
    options=list(targets_by_type.keys()),
    format_func=lambda t: {"s3": "S3 bucket", "secretsmanager": "Secrets Manager secret"}.get(t, t),
    horizontal=True,
)
type_targets = targets_by_type[target_type]
if not type_targets:
    st.warning(f"No {target_type} resources tagged JIT=true.")
    st.stop()

identifier = st.selectbox(
    "Resource",
    options=type_targets,
    format_func=lambda arn: arn.rsplit(":", 1)[-1],
)

actions = st.multiselect(
    "Actions",
    registry.actions_for(target_type),
    default=registry.actions_for(target_type)[:1],
)

DURATIONS = {"5 minutes": 5, "30 minutes": 30, "1 hour": 60, "3 hours": 180, "6 hours": 360}
duration = DURATIONS[st.selectbox("Duration", list(DURATIONS.keys()), index=1)]
justification = st.text_area("Justification (≥20 chars)", height=100)
ticket_ref = st.text_input("Ticket ref (optional)")

if st.button("Request access", type="primary"):
    res = evaluate(CheckRequest(
        user_groups=user.groups,
        mfa_verified=user.mfa_verified,
        target_type=target_type,
        actions=actions,
        duration_minutes=duration,
        justification=justification,
    ))
    if not res.allow:
        st.error(f"Denied: {', '.join(res.reasons)}")
        st.stop()

    grant_id = uuid.uuid4().hex[:12]
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=duration)
    principal = config.principal_for(user_email)
    target = registry.build(target_type, identifier)

    target.grant(principal, actions, grant_id)

    scheduler = boto3.client("scheduler")
    schedule_arn = scheduler.create_schedule(
        Name=f"jit-{grant_id}",
        GroupName=config.scheduler_group(),
        ScheduleExpression=f"at({expires_at.strftime('%Y-%m-%dT%H:%M:%S')})",
        FlexibleTimeWindow={"Mode": "OFF"},
        Target={
            "Arn":     config.janitor_lambda_arn(),
            "RoleArn": config.janitor_invocation_role_arn(),
            "Input":   json.dumps({"grant_id": grant_id}),
        },
        ActionAfterCompletion="DELETE",
    )["ScheduleArn"]

    ddb = boto3.resource("dynamodb").Table(config.grants_table_name())
    write_grant(ddb, Grant(
        grant_id=grant_id,
        user_email=user_email,
        user_sso_principal_pattern=principal,
        target_arn=target.target_arn,
        target_type=target_type,
        actions=actions,
        sid=f"jit{grant_id}",
        schedule_arn=schedule_arn,
        status=GrantStatus.ACTIVE,
        requested_at=now,
        expires_at=expires_at,
        duration_minutes=duration,
        justification=justification,
        ticket_ref=ticket_ref or None,
    ))

    st.success(f"Grant `{grant_id}` created — expires at {expires_at.isoformat()}.")
    st.info("Allow ~5 minutes for propagation, then assume your jit-requester AWS identity.")
