import streamlit as st

st.set_page_config(page_title="JIT Access", layout="wide")
st.title("JIT Access")

st.page_link("pages/request_access.py", label="Request access", icon="🔑")
st.page_link("pages/my_access.py",      label="My access",      icon="📋")
