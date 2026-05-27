# syntax=docker/dockerfile:1.7
FROM ghcr.io/astral-sh/uv:0.11.16-python3.12-trixie AS builder
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
COPY pyproject.toml uv.lock ./
COPY app/streamlit/pyproject.toml         app/streamlit/pyproject.toml
COPY app/lambdas/janitor/pyproject.toml   app/lambdas/janitor/pyproject.toml
RUN uv sync --frozen --no-dev --package jit-streamlit

FROM python:3.12-slim
RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -m -d /home/app app
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY app/__init__.py        /app/app/__init__.py
COPY app/shared             /app/app/shared
COPY app/streamlit          /app/app/streamlit
ENV PATH="/app/.venv/bin:$PATH" PYTHONPATH=/app
USER app
EXPOSE 8080
CMD ["streamlit", "run", "app/streamlit/src/main.py", \
     "--server.address=0.0.0.0", "--server.port=8080", \
     "--server.headless=true", "--browser.gatherUsageStats=false"]
