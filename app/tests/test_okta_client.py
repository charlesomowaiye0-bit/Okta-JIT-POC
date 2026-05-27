import httpx
import respx
from app.streamlit.src.lib.okta_client import OktaClient


def test_resolve_user():
    with respx.mock(base_url="https://dev.okta.com") as m:
        m.get("/api/v1/users/alice@gmail.com").mock(return_value=httpx.Response(200, json={
            "id": "00u1", "profile": {"email": "alice@gmail.com", "department": "engineering", "subteam": "developers"}
        }))
        m.get("/api/v1/users/00u1/groups").mock(return_value=httpx.Response(200, json=[
            {"profile": {"name": "jit-requesters"}}, {"profile": {"name": "team-developers"}}
        ]))
        m.get("/api/v1/users/00u1/factors").mock(return_value=httpx.Response(200, json=[{"status": "ACTIVE"}]))
        u = OktaClient("https://dev.okta.com", "t").resolve("alice@gmail.com")
    assert u.email == "alice@gmail.com" and "jit-requesters" in u.groups and u.mfa_verified
