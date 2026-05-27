# syntax=docker/dockerfile:1.7
FROM --platform=linux/arm64 ghcr.io/astral-sh/uv:0.11.16-python3.12-trixie AS builder
WORKDIR /build
COPY pyproject.toml uv.lock ./
COPY app/streamlit/pyproject.toml         app/streamlit/pyproject.toml
COPY app/lambdas/janitor/pyproject.toml   app/lambdas/janitor/pyproject.toml
RUN uv export --frozen --no-dev --package jit-janitor --no-hashes -o /build/requirements.txt

FROM --platform=linux/arm64 public.ecr.aws/lambda/python:3.12
COPY --from=builder /build/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt --target ${LAMBDA_TASK_ROOT}
COPY app/__init__.py            ${LAMBDA_TASK_ROOT}/app/__init__.py
COPY app/shared                 ${LAMBDA_TASK_ROOT}/app/shared
COPY app/lambdas/__init__.py    ${LAMBDA_TASK_ROOT}/app/lambdas/__init__.py
COPY app/lambdas/janitor        ${LAMBDA_TASK_ROOT}/app/lambdas/janitor
CMD ["app.lambdas.janitor.handler.handle"]
