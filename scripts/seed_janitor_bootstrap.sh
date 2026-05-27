#!/usr/bin/env bash
# Push a noop arm64 Lambda image to jit-janitor:bootstrap so
# lambda:CreateFunction has a valid image manifest at apply time.
# app-ci replaces this with the real handler image shortly after.
set -euo pipefail

URL=$(aws ecr describe-repositories --repository-names jit-janitor \
      --query 'repositories[0].repositoryUri' --output text)

if aws ecr describe-images --repository-name jit-janitor \
     --image-ids imageTag=bootstrap >/dev/null 2>&1; then
  echo ":: jit-janitor:bootstrap already present, skipping"
  exit 0
fi

aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin "${URL%/*}"

CTX=$(mktemp -d)
cat > "$CTX/Dockerfile" <<'DOCKERFILE'
FROM public.ecr.aws/lambda/python:3.12
RUN printf 'def handler(event, context):\n    return {"statusCode": 503, "body": "bootstrap placeholder"}\n' > /var/task/app.py
CMD ["app.handler"]
DOCKERFILE
docker buildx build \
  --platform linux/arm64 \
  --provenance=false --sbom=false \
  -t "$URL:bootstrap" \
  --push "$CTX"

aws ecr describe-images --repository-name jit-janitor \
  --image-ids imageTag=bootstrap >/dev/null \
  || { echo "::error::push reported success but :bootstrap tag not visible in jit-janitor"; exit 1; }
