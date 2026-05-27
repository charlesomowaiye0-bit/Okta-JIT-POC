import boto3
import streamlit as st
from datetime import datetime, timezone

from app.streamlit.src import config
from app.shared.grants import query_active_for_user, mark_revoked
from app.shared.targets import registry


st.title("My access")

if config.use_okta_sso():
    st.error("Okta SSO not wired yet (see spec §13).")
    st.stop()

users = config.test_users()
if not users:
    st.stop()

user_email = st.selectbox("Acting as", users)
ddb = boto3.resource("dynamodb").Table(config.grants_table_name())
grants = query_active_for_user(ddb, user_email)
if not grants:
    st.info("No active grants.")
    st.stop()

now = datetime.now(timezone.utc)
for g in grants:
    with st.container(border=True):
        st.markdown(f"**`{g.grant_id}`** — {g.target_type} `{g.target_arn}`")
        st.caption(f"Actions: {', '.join(g.actions)} | Expires in: {g.expires_at - now}")
        st.caption(f"Justification: {g.justification}")
        if st.button("Revoke now", key=g.grant_id):
            boto3.client("scheduler").delete_schedule(
                Name=f"jit-{g.grant_id}",
                GroupName=config.scheduler_group(),
            )
            registry.from_grant_arn(g.target_type, g.target_arn).revoke_by_grant_id(g.grant_id)
            mark_revoked(ddb, g.grant_id, reason="user_requested")
            st.success("Revoked.")
            st.rerun()
