#!/usr/bin/env bash
# Retag public nginx:1 (amd64) to jit-streamlit:bootstrap so the ECS task def
# has a valid image to reference at apply time. app-ci pushes the real
# Streamlit image shortly after.
set -euo pipefail

URL=$(aws ecr describe-repositories --repository-names jit-streamlit \
      --query 'repositories[0].repositoryUri' --output text)

if aws ecr describe-images --repository-name jit-streamlit \
     --image-ids imageTag=bootstrap >/dev/null 2>&1; then
  echo ":: jit-streamlit:bootstrap already present, skipping"
  exit 0
fi

aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin "${URL%/*}"
docker pull --platform linux/amd64 public.ecr.aws/docker/library/nginx:1
docker tag public.ecr.aws/docker/library/nginx:1 "$URL:bootstrap"
docker push "$URL:bootstrap"

aws ecr describe-images --repository-name jit-streamlit \
  --image-ids imageTag=bootstrap >/dev/null \
  || { echo "::error::push reported success but :bootstrap tag not visible in jit-streamlit"; exit 1; }
